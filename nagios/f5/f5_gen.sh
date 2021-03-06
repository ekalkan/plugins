#! /bin/sh

PATH="/bin:/usr/bin:/usr/sbin"
export PATH

f5_hosts="bigip1.yourcompany.local bigip2.yourcompany.local bigip3.yourcompany.local bigip4.yourcompany.local"
#f5_hosts="bigip4.yourcompany.local"
cd `dirname $0`
cfgupdated=0
for h in $f5_hosts
do
	echo "$h =>"
	timeout 600 ./f5.rb -c --host $h >f5_gen.tmp 2>&1
	res=$?
	echo "Result: $?" >>f5_gen.tmp
	if [ $res -gt 100 ]
	then
		uxtime="`date +%s`"
		# Timeout reached
		echo "[$uxtime] PROCESS_SERVICE_CHECK_RESULT;$h;status;3;Could not get updated config from $h due to timeout." >>$cmdfile
	fi
	cat f5_gen.tmp
	if [ -n "`egrep 'Config .* changed' f5_gen.tmp`" ]
	then
		cfgupdated=1
	fi
done
if [ $cfgupdated -eq 1 ]
then
	echo "Config updated. Reloading Nagios."
	sudo /usr/sbin/service nagios force-reload
else
	echo "Config did not change. No reason to reload Nagios."
fi
