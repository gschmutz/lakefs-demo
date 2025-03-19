# Data Versioning with LakeFS

Navigate to <http://192.168.1.115:28220/>

## Using DBeaver with Duckdb

```sql
INSTALL httpfs;
LOAD httpfs;
```

```sql
-- "s3_region" is the S3 region on which your bucket resides. If local storage, or not S3, then just set it to "us-east-1".
SET s3_region='us-east-1';
-- the host (and port, if necessary) of your lakeFS server
SET s3_endpoint='192.168.1.115:28220';
-- the access credentials for your lakeFS user
SET s3_access_key_id='V42FCGRVMK24JJ8DHUYG'; 
-- the access credentials for your lakeFS user
SET s3_secret_access_key='bKhWxVF3kQoLY9kFmt91l+tDrEoZjqnWXzY9Eza'; 
SET s3_url_style='path';
SET s3_use_ssl=false; 

-- Uncomment in case the endpoint listen on non-secure, for example running lakeFS locally.
-- SET s3_use_ssl=false;


SELECT   country, COUNT(*)
FROM     READ_PARQUET('s3://demo/denmark-lakes/lakes.parquet')
GROUP BY country
ORDER BY COUNT(*) 
DESC LIMIT 5;
```

## Using `awscli`

First configure a profile

```
aws configure --profile lakefs
```

```
> aws configure --profile lakefs
AWS Access Key ID [None]: XXXXXXXXXXXX
AWS Secret Access Key [None]: XXXXXXXXXXXXXXXX
Default region name [None]:
Default output format [None]:
```

When you invoke `aws s3`, you need to specify the `endpoint-url` parameter

```bash
aws s3 --profile lakefs --endpoint-url http://dataplatform:28220 ls s3://demo/main/tiny/
```

To make the command shorter and more convenient, you can create an alias:

```bash
alias awslfs='aws --endpoint-url http://dataplatform:28220 --profile lakefs'
```

```bash
awslfs s3 ls s3://demo/main/tiny/ --recursive
``` 

```bash
awslfs s3 ls s3://demo/main/ --recursive --human-readable
```

Upload data
 
```
awslfs s3 cp ./data-transfer/airports-data/airports.csv s3://demo/main/raw/airports/
```

Upload multiple files
 
```
awslfs s3 cp ./data-transfer/airports-data/ s3://demo/upload-201124/raw/airports/
```
 
Remove a folder
 
```
awslfs s3 rm s3://demo/main/tiny/orders/ --recursive
```

## Python from Jupyter

```bash
%%bash
cat <<EOF >> $HOME/.lakectl.yaml
credentials: 
  access_key_id: V42FCGRVMK24JJ8DHUYG
  secret_access_key: bKhWxVF3kQoLY9kFmt91l+tDrEoZjqnWXzY9Eza
server:
  endpoint_url: http://lakefs:8000
EOF
```


```python
import duckdb
from fsspec import filesystem

duckdb.register_filesystem(filesystem('lakefs'))

duckdb.sql("SELECT * FROM 'lakefs://demo/main/lakes.parquet'")
```
