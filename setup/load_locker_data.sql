ALTER SESSION SET DATE_INPUT_FORMAT = 'MM/DD/YY';

TRUNCATE TABLE "WHOOP"."DOCUMENTS"."LOCKER_DATA";
-- For more details, see: https://docs.snowflake.com/en/sql-reference/sql/truncate-table
COPY INTO "WHOOP"."DOCUMENTS"."LOCKER_DATA"
FROM (
    SELECT $1, $2, $3, $4
    FROM '@"WHOOP"."DOCUMENTS"."OTHERS"'
)
FILES = ('locker_data.csv')
FILE_FORMAT = (
    TYPE=CSV,
    SKIP_HEADER=1,
    FIELD_DELIMITER=',',
    TRIM_SPACE=TRUE,
    FIELD_OPTIONALLY_ENCLOSED_BY='"',
    REPLACE_INVALID_CHARACTERS=TRUE,
    DATE_FORMAT=AUTO,
    TIME_FORMAT=AUTO,
    TIMESTAMP_FORMAT=AUTO
)
ON_ERROR=ABORT_STATEMENT;
-- For more details, see: https://docs.snowflake.com/en/sql-reference/sql/copy-into-table
