#!/bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--host)
      HOST="$2"
      shift # past argument
      shift # past value
      ;;
    -u|--user)
      USER="$2"
      shift # past argument
      shift # past value
      ;;
    -p|--password)
      PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--database)
      DATABASE="$2"
      shift # past argument
      shift # past argument
      ;;
    -t|--type)
      TYPE="$2"
      shift # past argument
      shift # past argument
      ;;
    -i|--interval)
      INTERVAL="$2"
      shift # past argument
      shift # past argument
      ;;
    -r|--retries)
      RETRIES="$2"
      shift # past argument
      shift # past argument
      ;;
    -y|--table)
      TABLE="$2"
      shift # past argument
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters


# sanity check
if [[ -z "${HOST}" ]]
then
	echo "Error: argument --host is missing"
	exit 1
elif [[ -z "${USER}" ]]
then
	echo "Error: argument --user is missing"
	exit 1
elif [[ -z "${PASSWORD}" ]]
then
	echo "Error: argument --password is missing"
	exit 1
elif [[ -z "${DATABASE}" ]]
then
	echo "Error: argument --database is missing"
	exit 1
elif [[ -z "${TYPE}" ]]
then
	echo "Error: argument --type is missing"
	exit 1
fi

if [[ -z "$INTERVAL" ]]
then
  echo "Warn: argument --interval not found, default to 1(s)"
  INTERVAL=1
fi

if [[ -z "$RETRIES" ]]
then
  echo "Warn: argument --retires not found, default to 1"
  RETRIES=1
fi

if [[ "$INTERVAL" -lt 1 ]]
then
  echo "Warn: invalid interval '$INTERVAL', min: 1, default to 1(s)"
  INTERVAL=1
fi

if [[ "$RETRIES" -lt 1 ]]
then
  echo "Warn: invalid retries '$RETRIES', min: 1, default to 1"
  RETRIES=1
fi

echo "HOST              = ${HOST}"
echo "USER              = ${USER}"
echo "PASSWORD          = ${PASSWORD}"
echo "DATABASE          = ${DATABASE}"
echo "INTERVAL          = ${INTERVAL}"
echo "RETRIES           = ${RETRIES}"
echo "TABLE		= ${TABLE}"

# query initialize
if [[ $TYPE == "MSSQL" ]]
then
  QUERY_CHECK_DATABASE="SELECT 1"
	CMD_CHECK_DB=(sqlcmd -S $HOST -U $USER -P $PASSWORD -d $DATABASE -Q "${QUERY_CHECK_DATABASE}")
	if ! [[ -z "$TABLE" ]]
	then
		QUERY_CHECK_TABLE="SET NOCOUNT ON; SELECT COUNT(object_id) FROM sys.tables WHERE name='${TABLE}'"
		CMD_CHECK_TABLE=(sqlcmd -S $HOST -U $USER -P $PASSWORD -d $DATABASE -Q "${QUERY_CHECK_TABLE}" -h -1)
	fi
elif [[ $TYPE == "ORACLE" ]]
then
	CMD_CHECK_DB=(./check-oracle.sh $USER $PASSWORD $HOST $DATABASE)
  if ! [[ -z "$TABLE" ]]
	then
    echo "Warn: check oracle table exists is not yet supported."
		unset TABLE
	fi
elif [[ $TYPE == "MYSQL" ]]
then
  QUERY_CHECK_DATABASE="SELECT 1"
	CMD_CHECK_DB=(mysqlshow -h $HOST -u$USER -p$PASSWORD $DATABASE)
	if ! [[ -z "$TABLE" ]]
  then
    QUERY_CHECK_TABLE="SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DATABASE}' AND TABLE_NAME='${TABLE}'"
    CMD_CHECK_TABLE=(mysql -h $HOST -u$USER -p$PASSWORD -s -N -e "${QUERY_CHECK_TABLE}")
  fi

else
  echo "Error: unknown input argument type ${TYPE}, available type: MSSQL, ORACLE, MYSQL"
  exit 1
fi
echo "CMD_CHECK_DB	= ${CMD_CHECK_DB[@]}"
echo "CMD_CHECK_TABLE	= ${CMD_CHECK_TABLE[@]}"

#  main
COUNT=0
while  [ $COUNT -lt $RETRIES ]
do
	((COUNT=COUNT+1))
	if [[ $("${CMD_CHECK_DB[@]}") ]]
	then
		echo "Database(${DATABASE}): exists"
		if ! [[ -z "$TABLE" ]]
		then
			if [[ $("${CMD_CHECK_TABLE[@]}") -eq 1 ]]
			then
				echo "Table(${TABLE}): exists"
				exit 0
			else
				echo "Table(${TABLE}): not found, sleep ${INTERVAL}s"
        sleep $INTERVAL
			fi
		else
			exit 0
		fi
	else
		echo "Database(${DATABASE}): not found, sleep ${INTERVAL}s"
		sleep $INTERVAL
	fi
done

echo "Error: timeout waiting..."
exit 1
