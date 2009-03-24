#!/bin/sh


cd `dirname $0` || exit 1

. buildsys/functions
. ./dcps_functions

DATE=`date +%Y/%m/%d`
export DATE

setupBuildInfo()
{
   # Dump the stuff we want the overnight page to display to identify this build
   echo "PRODUCT=$PRODUCT" >> $LOGDIR/BUILDINFO
   echo "RUNNER=$RUNNER" >> $LOGDIR/BUILDINFO
   echo "LOG_HOST=$LOG_HOST" >> $LOGDIR/BUILDINFO
   echo "LOG_USER=$LOG_USER" >> $LOGDIR/BUILDINFO
   echo "RCP=$RCP" >> $LOGDIR/BUILDINFO
   echo "RSH=$RSH" >> $LOGDIR/BUILDINFO
   echo "REPOSITORY_URL=$REPOSITORY_URL" >> $LOGDIR/BUILDINFO
   echo "SETUP_TYPE=$SETUP_TYPE" >> $LOGDIR/BUILDINFO
   echo "BUILD_DIST=$BUILD_DIST" >> $LOGDIR/BUILDINFO
   echo "KEEP_DIST=$KEEP_DIST" >> $LOGDIR/BUILDINFO
   echo "RUN_DBT=$RUN_DBT" >> $LOGDIR/BUILDINFO
   echo "RUN_RBT=$RUN_RBT" >> $LOGDIR/BUILDINFO
   echo "RUN_EXAMPLES=$RUN_EXAMPLES" >> $LOGDIR/BUILDINFO
   echo "REV=$REV" >> $LOGDIR/BUILDINFO
   echo "VER=$VER" >> $LOGDIR/BUILDINFO
   echo "DEP=$DEP" >> $LOGDIR/BUILDINFO

   # List the fields we want the display page to show.
   echo "BUILD_DISPLAY=/SETUP_TYPE,/BUILD_DIST,/KEEP_DIST,RUN/DBT,RUN/RBT,RUN/EXAMPLES" >> $LOGDIR/BUILDINFO
}

ProcessArgs $*
ARGS=$*
Assert LoadConfigs
Assert SetupLogDir
Assert SetupResFile
Assert setupBuildInfo

ArchiveLogs

WaitForParentBuild

cat > $LOGDIR/LOGFILES <<EOF
BUILD=build.txt
BUILD_DBT=build-dbt-tests.txt
BUILD_RBT=build-rbt-tests.txt
RUN_DBT=perform-dbt-tests.txt
RUN_RBT=perform-rbt-tests.txt
BUILD_DIST=build-dist.txt
KEEP_DIST=archive-dist.txt
EOF

cat > $RESFILE <<EOF
BUILD=TODO
EOF

if [ $BUILD_DIST = "yes" ]
then
    echo "BUILD_DIST=TODO" >> $RESFILE
else
    echo "BUILD_DIST=SKIP" >> $RESFILE
fi
if [ $KEEP_DIST = "yes" ]
then
    echo "KEEP_DIST=TODO" >> $RESFILE
else
    echo "KEEP_DIST=SKIP" >> $RESFILE
fi
if [ $RUN_DBT = "yes" ]
then
    echo "BUILD/DBT=TODO" >> $RESFILE
    echo "RUN/DBT=TODO" >> $RESFILE
else
    echo "BUILD/DBT=SKIP" >> $RESFILE
    echo "RUN/DBT=SKIP" >> $RESFILE
fi
if [ $RUN_RBT = "yes" ]
then
    echo "BUILD/RBT=TODO" >> $RESFILE
    echo "RUN/RBT=TODO" >> $RESFILE
else
    echo "BUILD/RBT=SKIP" >> $RESFILE
    echo "RUN/RBT=SKIP" >> $RESFILE
fi
ArchiveLogs

./dcps_build $ARGS > $LOGDIR/build.txt 2>&1
LAST_STAGE_WORKED=$?

ArchiveLogs

if [ $LAST_STAGE_WORKED = 0 ]
then
    ./dcps_build_dist $ARGS > $LOGDIR/build-dist.txt 2>&1
    LAST_STAGE_WORKED=$?

    if test_build_dist $LOGDIR/build-dist.txt $LAST_STAGE_WORKED
    then
        echo "BUILD_DIST=PASS" >> $RESFILE
    else
        echo "BUILD_DIST=FAIL" >> $RESFILE
        LAST_STAGE_WORKED=1
    fi
    ArchiveLogs
fi

if [ $LAST_STAGE_WORKED = 0 ]
then
    ./dcps_archive_dist $ARGS > $LOGDIR/archive-dist.txt 2>&1
    LAST_STAGE_WORKED=$?
    ArchiveLogs
fi

if [ $LAST_STAGE_WORKED = 0 ]
then
    ./dcps_build_dbt_tests $ARGS > $LOGDIR/build-dbt-tests.txt 2>&1
    LAST_STAGE_WORKED=$?
    ArchiveLogs
fi
if [ $LAST_STAGE_WORKED = 0 ]
then
    ./dcps_perform_dbt_tests $ARGS > $LOGDIR/perform-dbt-tests.txt 2>&1
    LAST_STAGE_WORKED=$?
    ArchiveLogs
fi

if [ $LAST_STAGE_WORKED = 0 ]
then
    ./dcps_build_rbt_tests $ARGS > $LOGDIR/build-rbt-tests.txt 2>&1
    LAST_STAGE_WORKED=$?
    ArchiveLogs
fi
if [ $LAST_STAGE_WORKED = 0 ]
then
    ./dcps_perform_rbt_tests $ARGS > $LOGDIR/perform-rbt-tests.txt 2>&1
    LAST_STAGE_WORKED=$?
    ArchiveLogs
fi

if [ $LAST_STAGE_WORKED = 0 ]
then
   SetState "Complete"
else
   SetState "Failed"
fi
ArchiveLogs