
-------------------------------
-- Sample Data Insertion
-------------------------------

-- Sample data to populate the database for testing and demonstration purposes

-- Sample data for Site_Types
INSERT INTO "site_types"
("name", "soil_type", "nutrient_level", "sunlight_requirement", "water_requirement")
VALUES
('Sunny Lean Bed',           'sandy',      'low',    'full_sun',      'low'),
('Sunny Rich Perennial Bed', 'loamy',      'high',   'full_sun',      'medium'),
('Woodland Edge',            'humus_rich', 'medium', 'partial_shade', 'medium'),
('Woodland Floor',           'humus_rich', 'high',   'shade',         'high'),
('Dry Shade',                'loamy',      'low',    'shade',         'low'),
('Moist Meadow',             'clayey',     'medium', 'full_sun',      'high'),
('Pond Edge',                'wet',        'medium', 'full_sun',      'very_high'),
('Rock Garden',              'gravelly',   'low',    'full_sun',      'low');

-- Sample data for Plants
INSERT INTO "plants"
("common_name", "botanical_name", "primary_site_type_id", "plant_type", "soil_type", "nutrient_level", "sunlight_requirement", "water_requirement", "flowering_season", "height_cm", "flower_color")
VALUES
('Field Scabious',    'knautia_arvensis',        1, 'perennial', 'loamy',      'low',  'full_sun',      'low',    'summer', 50, 'purple'),
('Sticky Catchfly',   'lychnis_viscaria',        1, 'perennial', 'sandy',      'low',  'full_sun',      'medium', 'summer', 40, 'red'),
('Carthusian Pink',   'dianthus_carthusianorum', 8, 'perennial', 'gravelly',   'low',  'full_sun',      'low',    'summer', 30, 'pink'),
('Purple Coneflower', 'echinacea_purpurea',      2, 'perennial', 'loamy',      'high', 'full_sun',      'medium', 'summer',100, 'pink'),
('Lungwort',          'pulmonaria_officinalis',  4, 'perennial', 'humus_rich', 'high', 'partial_shade', 'medium', 'spring',30,  'blue'),
('Wild Columbine',    'aquilegia_vulgaris',      3, 'perennial', 'loamy',      'high', 'partial_shade', 'medium', 'spring',60,  'purple');

-- Sample data for Nurseries
INSERT INTO "nurseries"
("name", "phone", "email", "address", "url", "city", "state")
VALUES
('GreenLeaf Nursery', '040-1234567',  'info@greenleaf.de',     'Mühlenweg 5',    'http://greenleaf.de',  'Hamburg', 'Hamburg'),
('Nordgarten GmbH',   '0451-7654321', 'kontakt@nordgarten.de', 'Hafenstraße 12', NULL,                   'Kiel',    'Schleswig-Holstein'),
('Hanse Plant',       '0471-2345678', 'sales@hanseplant.de',   'Blumenallee 3',  'http://hanseplant.de', 'Bremen',  'Bremen');

-- Sample data for Customers
INSERT INTO "customers"
("first_name", "last_name", "phone", "email", "address")
VALUES
('Anna',  'Schmidt', '04121-555555', 'anna.schmidt@example.com',  'Finkenweg 8, Lübeck'),
('Max',   'Meyer',   '0431-777888',  'max.meyer@example.com',     'Gartenstraße 14, Kiel'),
('Laura', 'Fischer', '0421-999000',  'laura.fischer@example.com', 'Blumenweg 2, Bremen');

-- Sample data for Garden_Projects
INSERT INTO "garden_projects"
("customer_id", "project_type", "start_date", "budget")
VALUES
(1, 'Front Garden Redesign',  '2026-03-15', 2500),
(2, 'Backyard Flower Beds',   '2026-04-01', 1800),
(3, 'Community Garden Corner', NULL,        3000);

-- Sample data for Plant_Lists (plants assigned to projects)
INSERT INTO "plant_lists"
("project_id", "plant_id", "nursery_id", "quantity", "purchase_price_per_pot")
VALUES
(1, 1, 1, 10, 5),
(1, 2, 1, 5,  4),
(1, 5, 3, 8,  5),
(2, 3, 2, 12, 3),
(2, 4, 2, 6,  6),
(3, 6, 3, 10, 4),
(3, 1, 1, 15, 5);

-- Sample data for Availability
INSERT INTO "availability"
("plant_id", "nursery_id", "stock_quantity", "pot_size", "price_per_pot", "lead_time_days")
VALUES
(1, 1, 25, 'medium', 5, 7),
(2, 1, 15, 'small',  4, 10),
(3, 2, 40, 'small',  3, 5),
(4, 2, 30, 'large',  6, 14),
(5, 3, 20, 'medium', 5, 10),
(6, 3, 10, 'small',  4, 7);

-- Insert plants into project 1 using subqueries to resolve plant and nursery IDs automatically
INSERT INTO "plant_lists"
("project_id", "plant_id", "nursery_id", "quantity", "purchase_price_per_pot")
VALUES
(1,
(SELECT "id" FROM "plants" WHERE "botanical_name" = 'knautia_arvensis'),
(SELECT "id" FROM "nurseries" WHERE "name" = 'GreenLeaf Nursery'),
10, 5),
(1,
(SELECT "id" FROM "plants" WHERE "botanical_name" = 'lychnis_viscaria'),
(SELECT "id" FROM "nurseries" WHERE "name" = 'GreenLeaf Nursery'),
5, 4),
(1,
(SELECT "id" FROM "plants" WHERE "botanical_name" = 'pulmonaria_officinalis'),
(SELECT "id" FROM "nurseries" WHERE "name" = 'Hanse Plant'),
8, 5);

-- Add a new batch of plants to a project (updates project costs via triggers)
INSERT INTO "plant_lists"
("project_id", "plant_id", "nursery_id", "quantity", "purchase_price_per_pot")
VALUES
(3, 5, 2, 12, 4.50);

-------------------------------
-- Common Queries
-------------------------------

-- Select plants suitable for a specific site type (e.g., Sunny Lean Bed)
SELECT *
FROM "plant_catalog"
WHERE "site_type" = 'Sunny Lean Bed'
ORDER BY "common_name", "botanical_name";

-- Further filter plants by site type, flower color, and height for detailed planning
SELECT *
FROM "plant_catalog"
WHERE "site_type" = 'Sunny Lean Bed'
  AND "flower_color" = 'purple'
  AND "height_cm" <= 80
ORDER BY "common_name", "botanical_name";

-- View all ongoing projects using the active_projects view
SELECT * FROM "active_projects";

-- Check total quantities of each plant assigned to a specific project
SELECT
    p."common_name",
    p."botanical_name",
    SUM(pl."quantity") AS "total_quantity"
FROM "plant_lists" pl
JOIN "plants" p
    ON pl."plant_id" = p."id"
WHERE pl."project_id" = 3
GROUP BY p."id"
ORDER BY p."common_name", p."botanical_name";

-- Check available stock, pricing, and lead time for a specific plant at active nurseries
SELECT
    n."name" AS "nursery",
    a."stock_quantity",
    a."price_per_pot",
    a."lead_time_days"
FROM "availability" a
JOIN "nurseries" n
    ON a."nursery_id" = n."id"
WHERE
    a."plant_id" = 5
    AND (a."stock_quantity" > 0 OR a."lead_time_days" IS NOT NULL)
    AND n."is_deleted" = 0;

-- Update project status to 'completed' and set the end date
UPDATE "garden_projects"
SET "status" = 'completed',
    "end_date" = DATE('now')
WHERE "id" = 3;
