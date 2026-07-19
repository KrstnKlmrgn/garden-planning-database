
-------------------------------
-- Tables
-------------------------------

-- Represents common garden site locations
CREATE TABLE "site_types" (
    "id" INTEGER,
    "name" TEXT NOT NULL UNIQUE,
    "soil_type" TEXT NOT NULL,
    "nutrient_level" TEXT NOT NULL,
    "sunlight_requirement" TEXT NOT NULL,
    "water_requirement" TEXT,
    "is_deleted" INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY("id")
);
-- Represents plants preselected for use by the company
CREATE TABLE "plants" (
    "id" INTEGER,
    "common_name" TEXT NOT NULL,
    "botanical_name" TEXT NOT NULL UNIQUE,
    "primary_site_type_id" INTEGER,
    "plant_type" TEXT,
    "soil_type" TEXT,
    "nutrient_level" TEXT,
    "sunlight_requirement" TEXT,
    "water_requirement" TEXT,
    "height_cm" INTEGER,
    "flower_color" TEXT,
    "flowering_season" TEXT,
    "is_deleted" INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY("primary_site_type_id") REFERENCES "site_types"("id"),
    PRIMARY KEY("id")
);

-- Represents nurseries that supply plants for the company's projects
CREATE TABLE  "nurseries" (
    "id" INTEGER,
    "name" TEXT NOT NULL UNIQUE,
    "phone" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "url" TEXT,
    "city" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "is_deleted" INTEGER NOT NULL DEFAULT 0,
    Primary Key("id")
);

-- Represents customers requesting garden projects
CREATE TABLE "customers" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "is_deleted" INTEGER NOT NULL DEFAULT 0,
    Primary Key("id"),
    -- Composite uniqueness constraint at the table level
    CONSTRAINT "unique_customer" UNIQUE("first_name", "last_name", "phone")
);

-- Represents garden design projects requested by customers
CREATE TABLE "garden_projects" (
    "id" INTEGER,
    "customer_id" INTEGER NOT NULL,
    "project_type" TEXT NOT NULL,
    "start_date" NUMERIC,
    "end_date" NUMERIC,
    "budget" NUMERIC NOT NULL CHECK("budget" >= 0),
    "costs" NUMERIC DEFAULT NULL CHECK("costs" IS NULL OR "costs" >= 0),
    "status" TEXT NOT NULL DEFAULT 'in_planning',
    Primary Key("id"),
    FOREIGN KEY("customer_id") REFERENCES "customers"("id"),
    CHECK("costs" IS NULL OR "budget" IS NULL OR "costs" <= "budget"),
    CHECK("start_date" IS NULL OR "end_date" IS NULL OR "start_date" <= "end_date")
);

-- Represents plants assigned to garden projects, including quantity and source nursery
CREATE TABLE "plant_lists" (
    "id"  INTEGER NOT NULL,
    "project_id" INTEGER NOT NULL,
    "plant_id" INTEGER NOT NULL,
    "nursery_id" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL CHECK("quantity" > 0),
    "purchase_price_per_pot" NUMERIC NOT NULL CHECK("purchase_price_per_pot" >= 0),
    FOREIGN KEY("project_id") REFERENCES "garden_projects"("id") ON DELETE CASCADE,
    FOREIGN KEY("plant_id") REFERENCES "plants"("id") ON DELETE RESTRICT,
    FOREIGN KEY("nursery_id") REFERENCES "nurseries"("id") ON DELETE RESTRICT,
    PRIMARY KEY("id")
);

-- Represents plant availability at nurseries, including stock and supply details
CREATE TABLE "availability" (
    "plant_id" INTEGER NOT NULL,
    "nursery_id" INTEGER NOT NULL,
    "stock_quantity" INTEGER NOT NULL CHECK("stock_quantity" >= 0),
    "pot_size" TEXT NOT NULL,
    "price_per_pot" NUMERIC NOT NULL CHECK("price_per_pot" >= 0),
    "lead_time_days" INTEGER CHECK("lead_time_days" IS NULL OR "lead_time_days" >= 0), -- how fast plants arrive
    FOREIGN KEY("plant_id") REFERENCES "plants"("id") ON DELETE CASCADE,
    FOREIGN KEY("nursery_id") REFERENCES "nurseries"("id") ON DELETE CASCADE,
    PRIMARY KEY("plant_id", "nursery_id")
);

-------------------------------
-- Triggers
-------------------------------

-- Update project costs after new plants are added to a project
CREATE TRIGGER "update_project_costs_after_insert"
AFTER INSERT ON "plant_lists"
BEGIN
    UPDATE "garden_projects"
    SET "costs" = (
        SELECT SUM(pl."quantity" * pl."purchase_price_per_pot")
        FROM "plant_lists" pl
        WHERE pl."project_id" = NEW."project_id"
    )
    WHERE "id" = NEW."project_id";
END;

-- Update project costs after plant quantity is changed
CREATE TRIGGER "update_project_costs_after_update"
AFTER UPDATE OF "quantity", "plant_id", "nursery_id", "purchase_price_per_pot"
ON "plant_lists"
BEGIN
    UPDATE "garden_projects"
    SET "costs" = (
        SELECT SUM(pl."quantity" * pl."purchase_price_per_pot")
        FROM "plant_lists" pl
        WHERE pl."project_id" = NEW."project_id"
    )
    WHERE "id" = NEW."project_id";
END;

-- Update project costs after plants are removed from a project
CREATE TRIGGER "update_project_costs_after_delete"
AFTER DELETE ON "plant_lists"
BEGIN
    UPDATE "garden_projects"
    SET "costs" = (
        SELECT SUM(pl."quantity" * pl."purchase_price_per_pot")
        FROM "plant_lists" pl
        WHERE pl."project_id" = OLD."project_id"
    )
    WHERE "id" = OLD."project_id";
END;

-- Prevent changing the project_id on plant_lists to keep the costs correct
CREATE TRIGGER "prevent_project_id_change"
BEFORE UPDATE OF "project_id" ON "plant_lists"
BEGIN
    SELECT RAISE(ABORT, 'Cannot change project id of an existing plant batch.');
END;

-- Prevent editing a completed/cancelled project
CREATE TRIGGER "prevent_update_of_closed_projects"
BEFORE UPDATE ON "garden_projects"
WHEN OLD."status" IN ('completed', 'cancelled')
BEGIN
    SELECT RAISE(ABORT, 'Cannot modify a completed project.');
END;

-- Prevent deleting a completed project
CREATE TRIGGER "prevent_delete_of_closed_projects"
BEFORE DELETE ON "garden_projects"
WHEN OLD."status" = 'completed'
BEGIN
    SELECT RAISE(ABORT, 'Cannot delete a completed project.');
END;

-- Prevent editing plant lists of completed/cancelled projects: insert
CREATE TRIGGER "prevent_plant_insert_on_closed_projects"
BEFORE INSERT ON "plant_lists"
WHEN EXISTS (
    SELECT 1
    FROM "garden_projects"
    WHERE "id" = NEW."project_id"
        AND "status" IN ('completed', 'cancelled')
)
BEGIN
    SELECT RAISE(ABORT, 'Cannot add plants to a completed project.');
END;

-- Prevent editing plant lists of completed/cancelled projects: update
CREATE TRIGGER "prevent_plant_update_on_closed_projects"
BEFORE UPDATE ON "plant_lists"
WHEN EXISTS (
    SELECT 1
    FROM "garden_projects"
    WHERE "id" = OLD."project_id"
        AND "status" IN ('completed', 'cancelled')
)
BEGIN
    SELECT RAISE(ABORT, 'Cannot modify plants of a completed project.');
END;

-- Prevent deleting plant lists of completed/cancelled projects
CREATE TRIGGER "prevent_plant_delete_on_closed_projects"
BEFORE DELETE ON "plant_lists"
WHEN EXISTS (
    SELECT 1
    FROM "garden_projects"
    WHERE "id" = OLD."project_id"
        AND "status" IN ('completed', 'cancelled')
)
BEGIN
    SELECT RAISE(ABORT, 'Cannot remove plants from a completed project.');
END;

-- Delete all rows in availability table related to a soft-deleted nursery
CREATE TRIGGER "remove_availability_when_nursery_soft_deleted"
AFTER UPDATE OF "is_deleted" ON "nurseries"
WHEN NEW."is_deleted" = 1
BEGIN
    DELETE FROM "availability"
    WHERE "nursery_id" = NEW."id";
END;

-------------------------------
-- Views
-------------------------------

-- Overview of ongoing projects with customer info, budget, and plant totals
CREATE VIEW "active_projects" AS
SELECT
    gp."id" AS "project_id",
    c."first_name" || ' ' || c."last_name" AS "customer",
    gp."project_type",
    gp."status",
    gp."start_date",
    gp."costs",
    (gp."budget" - COALESCE(gp."costs", 0)) AS "remaining_budget",
    SUM(pl."quantity") AS "total_plants",
    COUNT(DISTINCT pl."plant_id") AS "distinct_plants"
FROM "garden_projects" gp
JOIN "customers" c
    ON gp."customer_id" = c."id"
LEFT JOIN "plant_lists" pl
    ON gp."id" = pl."project_id"
WHERE c."is_deleted" = 0
  AND gp."status" NOT IN ('completed', 'cancelled')
GROUP BY gp."id";

-- Catalog of non-deleted, available plants with details and primary site type
-- Designed for planners to quickly find plants suitable for specific garden sites
CREATE VIEW "plant_catalog" AS
SELECT
    p."id",
    p."common_name",
    p."botanical_name",
    st."name" AS "site_type",
    p."plant_type",
    p."height_cm",
    p."flower_color",
    p."flowering_season",
    p."soil_type",
    p."nutrient_level",
    p."sunlight_requirement",
    p."water_requirement"
FROM "plants" p
JOIN "site_types" st
    ON p."primary_site_type_id" = st."id"
WHERE p."is_deleted" = 0
  AND EXISTS (
      SELECT 1
      FROM "availability" a
      WHERE a."plant_id" = p."id"
        AND (a."stock_quantity" > 0 OR a."lead_time_days" IS NOT NULL)
  );

-------------------------------
-- Indexes
-------------------------------

-- Speeds up lookups of plants by their primary site type
-- Helps queries and views that filter or join on primary_site_type_id
CREATE INDEX "idx_plants_site_type_id"
ON "plants"("primary_site_type_id");

-- This makes the EXISTS checks for availability fast
-- Very important if availability grows
CREATE INDEX "idx_availability_plant_id"
ON "availability"("plant_id");

-- This makes looking at plant lists for specific projects fast
-- It also speeds up the cost calculation for a project
CREATE INDEX "idx_plant_lists_project_plant"
ON "plant_lists"("project_id", "plant_id");
