# lakeFS Demo Script

## Initialize Platform

Checkout the project and then run the `provision.sh` script once:

```bash
./provision.sh
```

```bash
cd $DATAPLATFORM_HOME
```

```bash
docker compose up -d
```

Navigate to <http://dataplatform:80/services-v2> to see the services

## lakeFS UI

Navigate to <http://dataplatform:28220> to open the lakeFS UI.

Login to lakeFs and you will see two repositories, `demo` (empty) and `lakefsdemo` (with the lakefs demo data loaded). We will work with the `demo` repository.


## Upload data using awscli

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
aws s3 --profile lakefs --endpoint-url http://dataplatform:28220 ls s3://demo/main/
```

To make the command shorter and more convenient, you can create an alias:

```bash
alias awslfs='aws --endpoint-url http://dataplatform:28220 --profile lakefs'
```

Upload data
 
```
awslfs s3 cp ./data-transfer/lakes.parquet s3://demo/main/lakes/lakes.parquet --content-type application/vnd.apache.parquet
```

Upload multiple files
 
```
awslfs s3 cp -r ./data-transfer/airports-data/ s3://demo/main/airports/  --recursive
```
 
```bash
awslfs s3 ls s3://demo/main/ --recursive
``` 


## Create a Branch

lakeFS uses branches in a similar way to Git. It’s a great way to isolate changes until, or if, we are ready to re-integrate them. lakeFS uses a zero-copy branching technique which means that it’s very efficient to create branches of your data.

### CLI (Docker)

```bash
docker exec lakectl \
    lakectl branch create \
	    lakefs://demo/denmark-lakes \
      --source lakefs://demo/main
```

```bash
ubuntu@ip-172-26-7-188:~/lakefs-demo/platys$ docker exec lakectl \
    lakectl branch create \
            lakefs://demo/denmark-lakes \
      --source lakefs://demo/main
Source ref: lakefs://demo/main
created branch 'denmark-lakes' a7dfd5f7ebae51a99457b4e11fe272e9679118f4870ca41218c6407aa01980b8
```

### CLI (local)

Create configuration

```bash
lakectl config
```

* `admin`
* `abc123abc123!`
* `lakefs://3.67.93.185:28220`

Create branch

```
lakectl branch create \
  lakefs://demo/denmark-lakes \
  --source lakefs://demo/main
```

### Using UI

From the [branches page](http://3.67.93.185:28220/repositories/demo/branches), click on Create Branch. Call the new branch denmark-lakes and click on Create


## Connect to LakeFS from DuckDB using DBeaver

Create a DuckDB connection and open a SQL editor

```sql
INSTALL httpfs;
LOAD httpfs;
```

```sql

-- "s3_region" is the S3 region on which your bucket resides. If local storage, or not S3, then just set it to "us-east-1".
SET s3_region='us-east-1';
-- the host (and port, if necessary) of your lakeFS server
SET s3_endpoint='3.67.93.185:28220';
-- the access credentials for your lakeFS user
SET s3_access_key_id='admin'; 
-- the access credentials for your lakeFS user
SET s3_secret_access_key='abc123abc123!'; 
SET s3_url_style='path';
SET s3_use_ssl=false; 

-- Uncomment in case the endpoint listen on non-secure, for example running lakeFS locally.
-- SET s3_use_ssl=false;
```

```sql
SELECT   country, COUNT(*)
FROM     READ_PARQUET('s3://demo/denmark-lakes/lakes.parquet')
GROUP BY country
ORDER BY COUNT(*) 
DESC LIMIT 5;
```

## Transforming the Data

Now we'll make a change to the data. lakeFS has several native clients, as well as an S3-compatible endpoint. This means that anything that can use S3 will work with lakeFS. Pretty neat.

Load data into DuckDB for transformation:

```sql
CREATE OR REPLACE TABLE lakes_raw AS 
    SELECT * FROM READ_PARQUET('s3://demo/denmark-lakes/lakes.parquet');
```

```sql
SELECT   country, COUNT(*)
FROM     lakes_raw
GROUP BY country
ORDER BY COUNT(*) 
DESC LIMIT 5;
```

```sql
DELETE FROM lakes_raw WHERE Country != 'Denmark';
```

```sql
SELECT   country, COUNT(*)
FROM     lakes_raw
GROUP BY country
ORDER BY COUNT(*) 
DESC LIMIT 5;
```

## Write data back to S3 (LakeFS)

Copy back to S3 (lakeFS)

```sql
COPY lakes_raw TO 's3://demo/denmark-lakes/lakes.parquet';
```

## Verify that the Data's Changed on the Branch

```sql
DROP TABLE lakes_raw;

SELECT   country, COUNT(*)
FROM     READ_PARQUET('s3://demo/denmark-lakes/lakes.parquet')
GROUP BY country
ORDER BY COUNT(*)
DESC LIMIT 5;
```


## What about the Data in Main?

```sql
SELECT   country, COUNT(*)
FROM     READ_PARQUET('s3://demo/main/lakes.parquet')
GROUP BY country
ORDER BY COUNT(*)
DESC LIMIT 5;
```

## Committing Changes in lakeFS 

### Using UI

Go to the [Uncommitted Changes](http://3.67.93.185:28220/repositories/demo/changes?ref=denmark-lakes) and make sure you have the denmark-lakes branch selected

### Using CLI (local)

```bash
lakectl commit lakefs://demo/denmark-lakes \
  -m "Create a dataset of just the lakes in Denmark"
```

```bash
guido.schmutz@AMAXDKFVW0HYY ~> lakectl commit lakefs://demo/denmark-lakes \
                                     -m "Create a dataset of just the lakes in Denmark"
Branch: lakefs://demo/denmark-lakes
Commit for branch "denmark-lakes" completed.

ID: 762069bfb52e4072cfc0bf33d178f25e14cc76e956f942c81f35b9032ef03d0f
Message: Create a dataset of just the lakes in Denmark
Timestamp: 2025-03-19 18:49:17 +0100 CET
Parents: a7dfd5f7ebae51a99457b4e11fe272e9679118f4870ca41218c6407aa01980b8
```

## Merging Branches in lakeFS 

### Using UI

Click [here](http://3.67.93.185:28220/repositories/demo/compare?ref=main&compare=denmark-lakes), or manually go to the Compare tab and set the Compared to branch to denmark-lakes.

### Using CLI (local)

```bash
lakectl merge \
  lakefs://demo/denmark-lakes \
  lakefs://demo/main
```

Rerun the same statement from `main` branch to see that merge has worked

```bash
SELECT   country, COUNT(*)
FROM     READ_PARQUET('s3://demo/main/lakes.parquet')
GROUP BY country
ORDER BY COUNT(*)
DESC LIMIT 5;
```

But…oh no! 😬 A slow chill creeps down your spine, and the bottom drops out of your stomach. What have you done! 😱 You were supposed to create a separate file of Denmark's lakes - not replace the original one 🤦🏻🤦🏻‍♀.

## Rolling back Changes in lakeFS

### CLI (Local)

```bash
lakectl branch revert \
  lakefs://demo/main \
  main --parent-number 1 --yes
```

```bash
guido.schmutz@AMAXDKFVW0HYY ~> lakectl branch revert \
                                     lakefs://demo/main \
                                     main --parent-number 1 --yes
Branch: lakefs://demo/main
commit main successfully reverted
```

Rerun the same statement from `main` branch to see that revert has worked

```sql

SELECT   country, COUNT(*)
FROM     READ_PARQUET('s3://demo/main/lakes.parquet')
GROUP BY country
ORDER BY COUNT(*)
DESC LIMIT 5;
```

## Actions and Hooks in lakeFS

In lakeFS create a new branch called `add_action`. You can do this through the UI or with lakectl:

## Using CLI (local)

```bash
lakectl branch create \
            lakefs://demo/add_action \
                    --source lakefs://demo/main
```

Create a file named `check_commit_metadata.yml` and add the following declaration

```bash
name: Check Commit Message and Metadata
on:
  pre-commit:
    branches: 
      - etl**
hooks:
  - id: check_metadata
    type: lua
    properties:
      script: |
        commit_message=action.commit.message
        if commit_message and #commit_message>0 then
            print("✅ The commit message exists and is not empty: " .. commit_message)
        else
            error("\n\n❌ A commit message must be provided")
        end

        job_name=action.commit.metadata["job_name"]
        if job_name == nil then
            error("\n❌ Commit metadata must include job_name")
        else
            print("✅ Commit metadata includes job_name: " .. job_name)
        end

        version=action.commit.metadata["version"]
        if version == nil then
            error("\n❌ Commit metadata must include version")
        else
            print("✅ Commit metadata includes version: " .. version)
            if tonumber(version) then
                print("✅ Commit metadata version is numeric")
            else
                error("\n❌ Version metadata must be numeric: " .. version)
            end
        end
```

```
lakectl fs upload \
        lakefs://demo/add_action/_lakefs_actions/check_commit_metadata.yml \
        --source ./check_commit_metadata.yml
```
                
Go to the Uncommitted Changes tab in the UI, and make sure that you see the new file in the path shown

Now we'll merge this new branch into main. From the Compare tab in the UI compare the main branch with add_action and click Merge.

## Testing the Action

When a commit is made to any branch that begins with etl:

  * the `commit message` must not be blank
  * there must be `job_name` and `version` metadata
  * the `version` must be numeric

Create a new branch and name it `etl_20250321`

Simulate an etl job

```sql
COPY (
    WITH src AS (
        SELECT lake_name, country, depth_m,
            RANK() OVER ( ORDER BY depth_m DESC) AS lake_rank
        FROM READ_PARQUET('s3://demo/etl_20250321/lakes.parquet'))
    SELECT * FROM SRC WHERE lake_rank <= 10
) TO 'lakefs://demo/etl_20250321/top10_lakes.parquet'  
```

View Uncommitted Changes tab in the UI and notice that there is now a file called `top10_lakes.parquet waiting to be committed.

Click on Commit Changes, leave the Commit message blank, and click Commit Changes to confirm.

