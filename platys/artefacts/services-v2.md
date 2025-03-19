# lakefs-platform - List of Services

| Service | Links | External<br>Port | Internal<br>Port | Description
|--------------|------|------|------|------------
|[jupyter](./documentation/services/jupyter )|[Web UI](http://192.168.1.112:28888)|28888<br>28376-28380<br>|8888<br>4040-4044<br>|Web-based interactive development environment for notebooks, code, and data
|[lakectl](./documentation/services/lakefs )||||Git-Like Data Version Control
|[lakefs](./documentation/services/lakefs )|[Web UI](http://192.168.1.112:28220) - [Rest API](http://192.168.1.112:28220/api/v1/repositories)|28220<br>|8000<br>|Git-Like Data Version Control
|[markdown-viewer](./documentation/services/markdown-viewer )|[Web UI](http://192.168.1.112:80)|80<br>|3000<br>|Platys Platform homepage viewer
|[minio-1](./documentation/services/minio )|[Web UI](http://192.168.1.112:9010)|9000<br>9010<br>|9000<br>9010<br>|Software-defined Object Storage
|[minio-mc](./documentation/services/minio )||||MinIO Console
|[spark-master](./documentation/services/spark )|[Web UI](http://192.168.1.112:28304)|28304<br>6066<br>7077<br>4040-4044<br>|28304<br>6066<br>7077<br>4040-4044<br>|Spark Master Node
|[spark-worker-1](./documentation/services/spark )||28111<br>|28111<br>|Spark Worker Node|

**Note:** init container ("init: true") are not shown