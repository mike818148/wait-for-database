# wait-for-database
Base image ubuntu 22.04. Installed with database clients  (mysql, sqlcmd, sqlplus). The main use case for this image is to play as the init-container(s) and wait for the database ready..

## Usage
```
./wait-for-database.sh -h $HOST -u $USER -p $PASSWORD -d $DATABASE(/SID) -t $TYPE(MYSQL/MSSQL/ORACLE) [-i $INTERVAL] [-r $RETRIES] [-y $TABLE]
```
