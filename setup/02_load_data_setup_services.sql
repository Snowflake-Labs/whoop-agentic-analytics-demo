-- Set date format for loading data

ALTER SESSION SET DATE_INPUT_FORMAT = 'MM/DD/YY';

CREATE OR REPLACE FILE FORMAT WHOOP.PUBLIC.CSV_FORMAT_WHOOP
    TYPE=CSV,
    PARSE_HEADER=TRUE,
    FIELD_DELIMITER=',',
    TRIM_SPACE=TRUE,
    FIELD_OPTIONALLY_ENCLOSED_BY='"',
    REPLACE_INVALID_CHARACTERS=TRUE,
    DATE_FORMAT=AUTO,
    TIME_FORMAT=AUTO,
    TIMESTAMP_FORMAT=AUTO
;

-- Create table using column info from csv via template function  

CREATE OR REPLACE TABLE WHOOP.PUBLIC.LOCKER_DATA USING TEMPLATE (

    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        WITHIN GROUP (ORDER BY ORDER_ID)
        FROM table (INFER_SCHEMA (
            LOCATION=>'@WHOOP.PUBLIC.RAW_DATA/LOCKER_DATA.csv'
            , FILE_FORMAT => 'WHOOP.PUBLIC.CSV_FORMAT_WHOOP'
            )));

-- Load locker data from csv skipping first row 

COPY INTO WHOOP.PUBLIC.LOCKER_DATA
FROM @WHOOP.PUBLIC.RAW_DATA/LOCKER_DATA.csv
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
);

-- Repeat with sample_activity_data.csv file 


CREATE OR REPLACE TABLE WHOOP.PUBLIC.SAMPLE_ACTIVITY_DATA USING TEMPLATE (

    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
        WITHIN GROUP (ORDER BY ORDER_ID)
        FROM table (INFER_SCHEMA (
            LOCATION=>'@WHOOP.PUBLIC.RAW_DATA/SAMPLE_ACTIVITY_DATA.csv'
            , FILE_FORMAT => 'WHOOP.PUBLIC.CSV_FORMAT_WHOOP'
            )));

COPY INTO WHOOP.PUBLIC.SAMPLE_ACTIVITY_DATA
FROM @WHOOP.PUBLIC.RAW_DATA/SAMPLE_ACTIVITY_DATA.csv
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
);


-- PDF chunking function 

CREATE OR REPLACE FUNCTION WHOOP.public.pdf_text_chunker(file_url STRING)
    RETURNS TABLE (chunk VARCHAR)
    LANGUAGE PYTHON
    RUNTIME_VERSION = '3.9'
    HANDLER = 'pdf_text_chunker'
    PACKAGES = ('snowflake-snowpark-python', 'PyPDF2', 'langchain')
    AS
$$
from snowflake.snowpark.types import StringType, StructField, StructType
from langchain.text_splitter import RecursiveCharacterTextSplitter
from snowflake.snowpark.files import SnowflakeFile
import PyPDF2, io
import logging
import pandas as pd

class pdf_text_chunker:

    def read_pdf(self, file_url: str) -> str:
        logger = logging.getLogger("udf_logger")
        logger.info(f"Opening file {file_url}")

        with SnowflakeFile.open(file_url, 'rb') as f:
            buffer = io.BytesIO(f.readall())

        reader = PyPDF2.PdfReader(buffer)
        text = ""
        for page in reader.pages:
            try:
                text += page.extract_text().replace('\n', ' ').replace('\0', ' ')
            except:
                text = "Unable to Extract"
                logger.warn(f"Unable to extract from file {file_url}, page {page}")

        return text

    def process(self, file_url: str):
        text = self.read_pdf(file_url)

        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size = 2000,  # Adjust this as needed
            chunk_overlap = 300,  # Overlap to keep chunks contextual
            length_function = len
        )

        chunks = text_splitter.split_text(text)
        df = pd.DataFrame(chunks, columns=['chunk'])

        yield from df.itertuples(index=False, name=None)
$$;

-- Chunk all available pdfs inside PDFS stage and place chunks into a table 

CREATE OR REPLACE TABLE WHOOP.PUBLIC.docs_chunks_table AS
    SELECT
        relative_path,
        build_scoped_file_url(@WHOOP.PUBLIC.PDFS, relative_path) AS file_url,
        -- preserve file title information by concatenating relative_path with the chunk
        CONCAT(relative_path, ': ', func.chunk) AS chunk,
        'English' AS language
    FROM
        directory(@WHOOP.PUBLIC.PDFS),
        TABLE(WHOOP.public.pdf_text_chunker(build_scoped_file_url(@WHOOP.PUBLIC.PDFS, relative_path))) AS func;


-- Create search services for locker and PDFs

CREATE OR REPLACE CORTEX SEARCH SERVICE  WHOOP.PUBLIC.LOCKER_SEARCH
  ON CONTENT
  ATTRIBUTES PUBLICATION_DATE
  WAREHOUSE = COMPUTE_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  AS (
    SELECT
        CONTENT,
        PUBLICATION_DATE,
        PUBLICATION_TITLE,
        PUBLICATION_ID
    FROM WHOOP.PUBLIC.LOCKER_DATA
);

CREATE OR REPLACE CORTEX SEARCH SERVICE  WHOOP.PUBLIC.PDF_SEARCH
  ON CHUNK
  ATTRIBUTES LANGUAGE
  WAREHOUSE = COMPUTE_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  AS (
    SELECT
        CHUNK,
        FILE_URL,
        LANGUAGE,
        RELATIVE_PATH
    FROM WHOOP.PUBLIC.DOCS_CHUNKS_TABLE
);

-- Uncomment for Claude 3.7 and Claude 4 
-- ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';