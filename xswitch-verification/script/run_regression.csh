#!/bin/csh -f

clear
echo CME 435 LAB 4 UVM

source /CMC/scripts/mentor.questasim.2020.1_1.csh

set rootdir = `dirname $0`
set rootdir = `cd $rootdir && pwd`

set timeout_duration=3

chmod u+x $rootdir/run_regression.csh

setenv QUESTA_HOME $CMC_MNT_QSIM_HOME
setenv UVM_HOME $QUESTA_HOME/verilog_src/uvm-1.2

set workdir = "$rootdir/.."
cd $rootdir
pwd

if (! -e $workdir ) then
  echo "ERROR: $workdir doesn't exist!"
  exit 0
else
  echo "Working directory: $workdir"
endif

# Phase 9 specific
if ($#argv == 0 || $#argv > 2 ) then
  echo "ERROR: Too many or too few arguments"
  echo "USAGE: $script_name -l | -t <testcase>"
  exit 0
endif

set testcase_list = `cat $workdir/verification/lab4_pkg.sv | grep "^[ ]*class test_" | sed -e 's/ *extends *[A-Za-z0-9_]*//' -e 's/class *//g' -e 's/;//g'`

switch ($argv[1])
  case "-l":
    if ($#argv > 1) then
        echo "ERROR: Too many arguments"
        exit 0
    else
      echo "List of test cases:"
      @ testcase_no = 0
      foreach testcase ($testcase_list)
        @ testcase_no++
        echo "  $testcase_no : $testcase"
      end
    endif
    breaksw
  case "-r":
    if ($#argv > 1) then
      echo "ERROR: Too many arguments"
      exit 0
    else
      if (! -e lab4_fcov_html) then
        mkdir ../lab4_fcov_html
      endif

      if (! -e lab4_fcov_rpt) then
        mkdir ../lab4_fcov_rpt
      endif

      if (! -e lab4_fcov_ucdb) then
        mkdir ../lab4_fcov_ucdb
      endif

      cd $workdir
      vlog -f ./script/lab_4.f

      foreach testcase ($testcase_list)
        pwd
        echo "$testcase_list"
        vsim -c tbench_top -L $QUESTA_HOME/uvm-1.2 +UVM_TESTNAME="$testcase" -do "coverage save -onexit ./lab4_fcov_ucdb/$testcase.ucdb; run -all; exit"
        vcover report -summary ./lab4_fcov_ucdb/$testcase.ucdb -output ./lab4_fcov_rpt/$testcase.rpt
        vcover report -summary ./lab4_fcov_ucdb/$testcase.ucdb -output ./lab4_fcov_html/$testcase.html
      end

      vcover merge ./lab4_fcov_ucdb/lab4_final.ucdb ./lab4_fcov_ucdb/test_sanity.ucdb ./lab4_fcov_ucdb/test_random.ucdb ./lab4_fcov_ucdb/test_duplicate_addr.ucdb ./lab4_fcov_ucdb/test_unique_addr.ucdb 
      vcover report -summary ./lab4_fcov_ucdb/lab4_final.ucdb -output lab4_fcov_rpt/lab4_final.rpt
      vcover report -details ./lab4_fcov_ucdb/lab4_final.ucdb -output lab4_fcov_html/lab4_final.html    
    
    endif
    breaksw
  case "-t":
    if ($#argv != 2) then 
      echo "ERROR: Too few arguments"
      exit 0
    else
      set test_specified = "$argv[2]"
      set test_exist = `echo $testcase_list | grep "$test_specified"`
      if ("$test_exist" != "") then
        cd $workdir
        echo "Running testcase $test_specified in $workdir"
        vlog -f $rootdir/lab_4.f
        vsim -c top -L $QUESTA_HOME/uvm-1.2 +UVM_TESTNAME=$test_specified <<!
        run -all
        !
      else
        echo "ERROR: Testcase $test_specified doesn't exist!"
        exit 0
      endif
    endif
    breaksw
  default:    
    echo "ERROR: invalid arguments"
    exit 0
endsw
