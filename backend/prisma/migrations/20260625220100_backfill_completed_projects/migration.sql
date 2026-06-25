UPDATE "Project"
SET "status" = 'completed'::"ProjectStatus"
WHERE "status" = 'active'::"ProjectStatus"
  AND "progressCache" >= 100;
