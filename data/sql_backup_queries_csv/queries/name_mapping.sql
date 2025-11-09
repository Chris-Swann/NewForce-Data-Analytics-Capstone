-- Update name_mapping table
UPDATE name_mapping
SET normalized_name = 'vincent viet'
WHERE alias_name = 'vincent viet';

-- Insert new alias_name and normalized names into name_mapping table
INSERT INTO name_mapping (alias_name, normalized_name)
VALUES
    ('vincent viet', 'vincent viet');


-- Delete unwanted or mis-entered normalized_name or alias_name
-- *Change WHERE clause accordingly
DELETE FROM name_mapping
WHERE normalized_name = 'kilian jornet brugada';

-- View all contents of name_mapping table
SELECT *
FROM name_mapping;