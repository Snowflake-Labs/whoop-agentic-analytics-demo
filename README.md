# whoop-agentic-analytics-demo

1. Run setup/db_setup.sql in a worksheet https://app.snowflake.com/_deeplink/worksheets 
2. Upload all PDF files inside data/ to WHOOP.PUBLIC.PDFS stage. Deeplink: https://app.snowflake.com/_deeplink/#/data/add-data 
3. Upload data/locker_data.csv to WHOOP.PUBLIC.RAW_DATA stage
4. Upload sample_semantic_model.yaml to WHOOP.PUBLIC.SEMANTIC_MODELS stage
5. Run setup/load_locker_data.sql in a worksheet https://app.snowflake.com/_deeplink/worksheets 
6. Run setup/pdf_parser.sql in a worksheet
7. Run setup/search_services.sql in a worksheet
