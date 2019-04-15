######################################################################################################################################
# Make sure Afterburner is on and set to the right preset
# It should be set to start with Windows and automatically load the last profile used
# You can set shortcut keys to switch profiles

# Use larger mining pools so that you can submit shares more frequently.
# This is so that you waste less processing power by abandoning current shares when restarting the miner

# Primary PS will RUN AS ADMIN (UAC Settings disabled) with other Startup programs

param
(
	[Parameter(Mandatory = $true)]
	[int] $gpu_quantity,
	[Parameter(Mandatory = $true)]
	[String] $pc_num
	[Parameter(Mandatory = $false)]
	[String] $pc_name = "$env:computername"
)

Import-Module -Force "D:\Library_Crypto\Miners\Module - GPU.psm1"
Import-Module -Force "D:\Library_Crypto\Miners\Module - CURRENCY.psm1"

# Readability functions
function CHANGE_DIRECTORY_TO_NVSMI
{
	cd $nvsmi_dir
}

function CHANGE_WINDOW_NAME([String] $new_name)
{
	$Host.UI.RawUI.WindowTitle = $new_name
}

function WAIT_10_SECONDS
{
	Start-Sleep -s 10
}

function WAIT_5_SECONDS
{
	Start-Sleep -s 5
}

# Initialization functions (Run once at start)
function MAKE_GPU_LIST
{
	# Display list of GPUs with NVSMI to make sure they are detected
	Invoke-Expression "$nvsmi --list-gpus"
	
	# Extra check for unrecognized GPUs
	GPU_TEST_UNRECOGNIZED

	#Create GPU objects to correspond with the physical GPUs for the sake of indexing nvsmi parameters
	For ($i = 0; $i -lt $gpu_quantity; $i++)
	{
		$some_gpu = Get-GPU()
		$some_gpu.index = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=index"
		$some_gpu.name = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=name"
		$some_gpu.default_power_limit = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=power.default_limit"
		
		###################################################################################### update these figures
		################################################################################### $global:some_gpu.neoscrypt ????
		If ($some_gpu.name -contains '1070')
		{
			$some_gpu.equihash  =	430.0
			$some_gpu.neoscrypt =	1000000.0
			$some_gpu.lbry 		=	270000000.0
		}
		ElseIf ($some_gpu.name -contains '1080 Ti')
		{
			$some_gpu.equihash  = 	685.0
			$some_gpu.neoscrypt =	1400000.0
			$some_gpu.lbry 		=	460000000.0
		}
		ElseIf ($some_gpu.name -contains '1080') # Must come after 1080Ti
		{
			$some_gpu.equihash  = 	550.0
			$some_gpu.neoscrypt =	1060000.0
			$some_gpu.lbry 		=	360000000.0
		}
		
		$global:gpu_array += $some_gpu
	}
	
	# Display list of GPU properties as a table
	$gpu_array
}

function MAKE_HASH_RATE_LIST
{
	ForEach ($i in $gpu_array)
	{
		$global:equihash_hash += $i.equihash_hash
		$global:neoscrypt_hash += $i.neoscrypt_hash
		$global:lbry_hash += $i.lbry_hash
	}
}

function MAKE_CURRENCY_LIST
{
	# Miner locations and constant parameters
	[String] $EWBF_dir = "C:\MyToolbars\Mining\EWBF-0.3.4b\miner.exe"
	[String[]] $EWBF_const = "--eexit 3", "--fee 0", "--log 1", "--pass x", "--intensity 20"
	
	[String] $HSR_NEOS_dir = "C:\MyToolbars\Mining\hsrminer-1.0.1\hsrminer_neoscrypt.exe"
	[String[]] $HSR_NEOS_const = "-p x"
	
	[String] $CC_dir = "C:\MyToolbars\Mining\ccminer-2.2\ccminer-x64.exe"
	[String[]] $CC_const = "-u Gilfoyle.$pc_num","-p x"

	# Currency properties and unique parameters
	[CURRENCY]$Hush
	$Hush.tag = "HUSH"
	$Hush.algo = "Equihash"
	$Hush.miner = "EWBF"
	$Hush.FileName = $EWBF_dir
	$Hush.Arguments = $EWBF_const + "--server us.miningspeed.com", "--port 3092", "--user t1drNDZgUXdsqmMsALJgkUCvVjsX42dzsN2.$pc_num"
	
	[CURRENCY]$ZCash
	$ZCash.tag = "ZEC"
	$ZCash.algo = "Equihash"
	$ZCash.miner = "EWBF"
	$ZCash.FileName = $EWBF_dir
	$ZCash.Arguments = $EWBF_const + "--server coinotron.com", "--port 3346", "--user Gilfoyle.$pc_num"
	
	[CURRENCY]$ZClassic
	$ZClassic.tag = "ZCL"
	$ZClassic.algo = "Equihash"
	$ZClassic.miner = "EWBF"
	$ZClassic.FileName = $EWBF_dir
	$ZClassic.Arguments = $EWBF_const + "--server us.miningspeed.com", "--port 3052", "--user t1Y6hi6A7rieNJPfNTZ2wAYyLxU6cEr5WB2.$pc_num"
	
	[CURRENCY]$ZenCash
	$ZenCash.tag = "ZEN"
	$ZenCash.algo = "Equihash"
	$ZenCash.miner = "EWBF"
	$ZenCash.FileName = $EWBF_dir
	$ZenCash.Arguments = $EWBF_const + "--server us.miningspeed.com", "--port 3062", "--user znodfAhg6kokv59yq1TQPqv1iob26qWMS4y.$pc_num"
	
	[CURRENCY]$FeatherCoin
	$FeatherCoin.tag = "FTC"
	$FeatherCoin.algo = "NeoScrypt"
	$FeatherCoin.miner = "hsrminer"
	$FeatherCoin.FileName = $HSR_NEOS_dir
	$FeatherCoin.Arguments = $HSR_NEOS_const + "-o stratum+tcp://coinotron.com:3337 -u Gilfoyle.$pc_num"
	
	[CURRENCY]$GoByte
	$GoByte.tag = "GBX"
	$GoByte.algo = "NeoScrypt"
	$GoByte.miner = "hsrminer"
	$GoByte.FileName = $HSR_NEOS_dir
	$GoByte.Arguments = $HSR_NEOS_const + "-o stratum+tcp://eu1.altminer.net:10000 -u GegyFjGSyxLdFWDGarYPk9kSn8q6euA1yi.$pc_num"
	
	[CURRENCY]$TrezarCoin
	$TrezarCoin.tag = "TZC"
	$TrezarCoin.algo = "NeoScrypt"
	$TrezarCoin.miner = "hsrminer"
	$TrezarCoin.FileName = $HSR_NEOS_dir
	$TrezarCoin.Arguments = $HSR_NEOS_const + "-o stratum+tcp://eu1.altminer.net:10002 -u TromG4g2Ty5NmRMWBYSzdWGzTyBnDZpL4p.$pc_num"
	
	[CURRENCY]$Vivo
	$Vivo.tag = "VIVO"
	$Vivo.algo = "NeoScrypt"
	$Vivo.miner = "hsrminer"
	$Vivo.FileName = $HSR_NEOS_dir
	$Vivo.Arguments = $HSR_NEOS_const + "-o stratum+tcp://eu1.altminer.net:10001 -u VJJGoHxsYW2QyeG8Ftp12D2W35TCt6ef5Q.$pc_num"
	
	[CURRENCY]$VertCoin
	$VertCoin.tag = "VTC"
	$VertCoin.algo = "Lyra2REv2"
	$VertCoin.miner = "ccminer"
	$VertCoin.FileName = $CC_dir
	$VertCoin.Arguments = $CC_const + "-a lyra2v2", "-o stratum+tcp://coinotron.com:3340", "-N 30", "-q", "-i 22.4"
	
	[CURRENCY]$LBRY
	$LBRY.tag = "LBC"
	$LBRY.algo = "LBRY"
	$LBRY.miner = "ccminer"
	$LBRY.FileName = $CC_dir
	$LBRY.Arguments = $CC_const + "-a lbry", "-o stratum+tcp://lbry.suprnova.cc:6256", "-N 30", "-q", "-i 24.0"
	
	# Add currencies to array
	$global:currency_array += [CURRENCY]$Hush, [CURRENCY]$ZCash, [CURRENCY]$ZClassic, [CURRENCY]$ZenCash
	$global:currency_array += [CURRENCY]$FeatherCoin, [CURRENCY]$GoByte, [CURRENCY]$TrezarCoin, [CURRENCY]$Vivo
	$global:currency_array += [CURRENCY]$VertCoin, [CURRENCY]$LBRY
}

# Initialization & check-up functions

function PROFITABILITY ([String] $status)
{
	# PROFITABILITY() has the functionality of UPDATE_NETWORK_HASH_RECORDS() built into it via $this_currency.CALCULATE_PROFITABILITY() via UPDATE_NETWORK_HASHES()
	# in order to minimize calls to the API because I don't want to risk getting cut off from over-use, and I don't want to waste bandwidth

	#  PERFORMANCE RATIOS RELATIVE TO EQUIHASH (whattomine.com)
	# GPUs		CryptoNight	Equihash	NeoScrypt
	# 1060		430			270			620			
	# 1070		630			430			1000		1.47 : 1.00 : 2.33
	# 1070Ti	630			470			1050		1.34 : 1.00 : 2.23
	# 1080		580			550			1060		1.05 : 1.00 : 1.93
	# 1080Ti	830			685			1400		1.21 : 1.00 : 2.04
	
	# https://api.coinmarketcap.com/v1/ticker returns an array object, so it can be sorted through with commands like 'where {$_.id -eq "bitcoin"}' and array indices
	
	# https://whattomine.com/coins.json returns a custom object that contains each coin as their own custom object, and so they can't be sorted through.
	# Their properties need to be accessed as if you were dealing with #C objects
	
	# Get the full set of coins and all of their useful information, but prices are in bitcoin/currency
	# BACKUP FOR BITCOIN PRICE:   https://apiv2.bitcoinaverage.com/convert/global?from=BTC&to=USD&amount=1
	# I'm not sure which of these only include North American markets
	$all_coin_stats = (Invoke-WebRequest -Uri https://whattomine.com/coins.json | ConvertFrom-Json).coins
	$usd_per_bitcoin = (Invoke-WebRequest -Uri https://api.coinmarketcap.com/v1/ticker/bitcoin/ | ConvertFrom-Json).price_usd
	
	# Every currency has their $net_hash[] array initialized
	If ($status -eq "initialize")
	{
		ForEach ($this_currency in $currency_array) 
		{
			#used to 
			$24h_net_hash = 
			$latest_net_hash = $all_coin_stats.($this_currency.name).nethash
			
			$this_currency.INITIALIZE_NETWORK_HASHES( $24h_net_hash, $latest_net_hash )
		}
	}
	
	# Make blank CURRENCY object to store the best one in
	[CURRENCY] $best_currency = Get-CURRENCY()
	$best_currency.my_reward_in_usd = 0
		
	# Find the most profitable currency
	ForEach ($this_currency in $currency_array)
	{
		$this_currency.CALCULATE_PROFITABILITY( $all_coin_stats.($this_currency.name), $usd_per_bitcoin )
		If ($this_currency.my_reward_in_usd -gt $best_currency.my_reward_in_usd) { $best_currency = $this_currency }
		"Calculated: $this_currency.my_reward_in_currency ($this_currency.my_reward_in_usd), Predicted: $this_currency.my_predicted_reward_in_currency"
	}
	
	# Restart miner if there is a more profitable currency, or if it was inactive
	If ($best_currency.tag -ne $currency.tag -or $status -eq "inactive" -or $status -eq "initialize")
	{
		$global:currency = $best_currency
		NEW_MINER
		Return $true
	}
	
	Return $false
}

function NEW_MINER #Is only callled from PROFITABILITY(string) - updates $currency
{
	# If miner is already on, turn it off (kill) and erase any trace of it from $process (dispose)
	# Also wait 5s to give the GPUs a chance to clear their memory properly
	[String] $state = $process
	
	# Only shut down the process if it has a name
	If ($state -ne "System.Diagnostics.Process")
	{
		$global:process.kill()
		$global:process.dispose()
		WAIT_5_SECONDS
	}

	#Change script's window name to reflect new currency
	CHANGE_WINDOW_NAME("$curreny.miner's $currency.name with $pc_name's Miner Manager")
	
	#Run new miner process with updated currency
	$global:process.StartInfo.FileName = $currency.FileName
	$global:process.StartInfo.Arguments = $currency.Arguments
	$global:process.Start()
}

# Check-up functions (Run in intervals)
function UPDATE_NETWORK_HASH_RECORDS
{	
	$all_coin_stats = (Invoke-WebRequest -Uri https://whattomine.com/coins.json | ConvertFrom-Json).coins
	
	ForEach ($this_currency in $currency_array) { $this_currency.UPDATE_NETWORK_HASHES( $all_coin_stats.($this_currency.name).nethash ) }
}

function POWER_USAGE
{
	[int] $current_hour = Get-Date -Format %h
	[float] $percent_power_limit
	
	If ($current_hour -ge 0 -and $current_hour -lt 4)		{$percent_power_limit = 0.85}	#12AM - 4AM		# Low
	ElseIf ($current_hour -ge 4 -and $current_hour -lt 5)	{$percent_power_limit = 0.80}	#4AM - 5AM
	ElseIf ($current_hour -ge 5 -and $current_hour -lt 6)	{$percent_power_limit = 0.75}	#5AM - 6AM
	ElseIf ($current_hour -ge 6 -and $current_hour -lt 9)	{$percent_power_limit = 0.70}	#6AM - 9AM		# Peak
	ElseIf ($current_hour -ge 9 -and $current_hour -lt 18)	{$percent_power_limit = 0.75}	#9AM - 6PM
	ElseIf ($current_hour -ge 18 -and $current_hour -lt 21)	{$percent_power_limit = 0.70}	#6PM - 9PM		# Peak
	ElseIf ($current_hour -ge 21 -and $current_hour -lt 22)	{$percent_power_limit = 0.75}	#9PM - 10PM
	ElseIf ($current_hour -ge 22 -and $current_hour -lt 23) {$percent_power_limit = 0.80}	#10PM - 11PM
	ElseIf ($current_hour -eq 23)							{$percent_power_limit = 0.85}	#11PM - 12AM	# Low
	
		
	For ($i = 0; $i -lt $gpu_quantity; $i++)
	{
		
		If ($gpu_array[$i].name -contains "1080 Ti" -and $percent_power_limit -gt 0.75) { $global:percent_power_limit = 0.75 }
		
		$gpu_array[$i].current_power_limit = $gpu_array[$i].default_power_limit * $percent_power_limit
		Invoke-Expression "$nvsmi --id=$i --power-limit=$gpu_array[$i].current_power_limit"
	}
}

function DETAILED_ACTIVITY
{
	For ($i = 0; $i -lt $gpu_quantity; $i++)
	{
		$gpu_array[$i].current_power_limit = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=power.limit"
		$gpu_array[$i].power_draw = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=power.draw"
		$gpu_array[$i].temperature = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=temperature.gpu"
		$gpu_array[$i].cr_clock = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=clocks.gr"
		$gpu_array[$i].mem_clock = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=clocks.mem"
		$gpu_array[$i].UPDATE_UTIL(Invoke-Expression "$nvsmi_format --id=$i --query-gpu=utilization.gpu")
		
		$c1 = $gpu_array[$i].index
		$c2 = $gpu_array[$i].name
		$c3 = $gpu_array[$i].power_draw
		$c4_1 = $gpu_array[$i].current_power_limit
		$c4_2 = $gpu_array[$i].default_power_limit
		$c4_3 = $c4_1 / $c4_2 * 100
		$c5 = $gpu_array[$i].temperature
		$c6 = $gpu_array[$i].cr_clock
		$c7 = $gpu_array[$i].mem_clock
		$c8_1 = $gpu_array[$i].utilization[0]
		$c8_2 = $gpu_array[$i].utilization[1]
		$c8_3 = $gpu_array[$i].utilization[2]
		$c8_4 = $gpu_array[$i].utilization[3]
		$c8_5 = $gpu_array[$i].utilization[4]
		
		"$c1 | $c2 `t| ($c3) $c4_1 / $c4_2 = $c4_3% `t| $c5 C, $c6 MHz, $c7 MHz `t|`t$c8_1`t$c8_2`t$c8_3`t$c8_4`t$c8_5"############################################################
		
		$c0 = $gpu_array[$i].index
		$c1 = $gpu_array[$i].name
		$c2 = $gpu_array[$i].power_draw
		$c3 = $gpu_array[$i].current_power_limit
		$c4 = $gpu_array[$i].default_power_limit
		$c5 = $c4_1 / $c4_2 * 100
		$c6 = $gpu_array[$i].temperature
		$c7 = $gpu_array[$i].cr_clock
		$c8 = $gpu_array[$i].mem_clock
		$c9 = $gpu_array[$i].utilization[0]
		$c10 = $gpu_array[$i].utilization[1]
		$c11 = $gpu_array[$i].utilization[2]
		$c12 = $gpu_array[$i].utilization[3]
		$c13 = $gpu_array[$i].utilization[4]
		
		[console]::Writeline("{0} {1,20} | ({2,3}) {3,3}/{4,3}={5,3}% | {6}C {7,4}MHz {8,4}Mhz | {9,2} {10,2} {11,2} {12,2} {13,2}", $c0, $c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $c10, $c11, $c12, $c13)
	}
}

function INACTIVE_MINER
{
	# Make sure every gpu is being utilized by at least 20% for 5 consecutive utilization checks
	# Utilization = -1 means that the miner didn't run long enough to create an old enough record
	For ($i = 0; $i -lt $gpu_quantity; $i++)
	{
		$strikes = 0
	
		For ($u = 0; $u -lt 5; $u++)
		{
			If ($gpu_array[$i].utilization[$u] -lt 20 -and $gpu_array[$i].utilization[$u] -gt 0) { $global:strikes += 1 }
		}
		
		If ($strikes -eq 5)
		{
			PROFITABILITY ("inactive")
			Return $true
		}
	}
	
	Return $false
}

function GPU_TEST_UNRECOGNIZED
{
	# Check that every GPU counted matches what was started with
	[int[]] $count_result = Invoke-Expression "$nvsmi_format --query-gpu=count"
	$gpu_detected = $count_result[0]
	If ($gpu_detected -ne $gpu_quantity) {restart-computer}
	
	# Check that every detected GPU has a clock speed that can indicate that they work
	# The exact ID of each GPU is irrelevant
	For ($i = 0; $i -lt $gpu_quantity; $i++)
	{
		$clock_1 = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=clocks.current.graphics"
		$clock_2 = Invoke-Expression "$nvsmi_format --id=$i --query-gpu=clocks.current.memory"
		If ($clock_1 -eq 0 -or $clock_2 -eq 0) {restart-computer}
	}
	
	# Send an error message to main PC on LAN if there is an issue#######################################################
}



# Global Variables
[System.Diagnostics.Process] $process = New-Object System.Diagnostics.Process
[GPU[]] $gpu_array = @()
[CURRENCY[]] $currency_array = @()
[CURRENCY] $currency
Set-Variable hash_record_length -value ([int] 720) -option Constant # 1 check every minute for the past 12 hours

[float] $equihash_hash = 0
[float] $neoscrypt_hash = 0
[float] $lbry_hash = 0


Set-Variable nvsmi_dir -value ([string] "C:\Program Files\NVIDIA Corporation\NVSMI") -option Constant
Set-Variable nvsmi = "./nvidia-smi.exe" -option Constant
Set-Variable nvsmi_format = "$nvsmi --format=csv,noheader,nounits" -option Constant
Set-Variable five_seconds -value ([int] 5) -option Constant

Set-Variable check_power -value ([int] 60) -option Constant
Set-Variable check_unrecognized -value ([int] 900) -option Constant
Set-Variable check_profitability -value ([int] 300) -option Constant
Set-Variable check_network_hash -value ([int] 60) -option Constant
Set-Variable check_detailed_activity -value ([int] 5) -option Constant
Set-Variable check_inactive -value ([int] 15) -option Constant



# Set temporary name for script's window
CHANGE_WINDOW_NAME( "$pc_name's Miner Manager" )

# Change directory to location of nvidia-smi.exe
CHANGE_DIRECTORY_TO_NVSMI

# Give the PC 10 seconds to fully wake up
WAIT_10_SECONDS

# Make sure PC can recognize all GPUs and store their properties in [GPU[]] $gpu_array = @()
MAKE_GPU_LIST

# Calculate the cumulative hashrates of the GPUs
MAKE_HASH_RATE_LIST

# Set properties for all currencies and store them in [CURRENCY[]] $currency_array = @()
MAKE_CURRENCY_LIST

# Initialize the first instance of a miner for $process, and give a value to $currency
PROFITABILITY( "initialize" )

# Check regularly for power setting updates, GPU problems, profitability updates, and software problems
while ($true)
{
	# Reset timers
	[int] $timer_power = 0
	[int] $timer_unrecognized = 0
	[int] $timer_profitability = 0
	[int] $timer_network_hash = 0
	[int] $timer_detailed_activity = 0
	[int] $timer_inactive
	
	# Give the GPUS time to become fully utilized		
	If		($currency.miner -eq "EWBF")		{$timer_inactive = -10}
	ElseIf	($currency.miner -eq "hsrminer")	{$timer_inactive = -30}
	ElseIf	($currency.miner -eq "ccminer")		{$timer_inactive = -120}
	
	[int] $current_hour = Get-Date -Format %h
	
	# Check here just in case the miner resets too often
	POWER_USAGE
	GPU_TEST_UNRECOGNIZED
	
	while ($true)
	{
		#Wait for 5s and increment timers
		WAIT_5_SECONDS
		$timer_power += $five_seconds
		$timer_unrecognized += $five_seconds
		$timer_profitability += $five_seconds
		$timer_network_hash += $five_seconds
		$timer_detailed_activity += $five_seconds
		$timer_inactive += $five_seconds
		
		
		# The inactivity check and profitability check reset each other's timers if they return true,
		# since returning true means that the miner was restarted and the profitability was recalculated.
		# Profitability should not be calculated in intervals that are too small since some coins take a 
		# while to generate shares, and inactivity should not be checked too quickly after a restart
		# since the miners need to time to fully utilize all GPUs.
		# The unrecognize check restarts the PC if necessary
		
		# http://www.atcoenergysense.com/Documents/Managing_Electricity_at_Home_2015_web_final.pdf
		
		# Check if the power limit should be modified based on the time of day
		If ($check_power -le $timer_power)
		{
			$global:timer_power = 0
			If ($current_hour -ne Get-Date -Format %h) {POWER_USAGE}
		}		
		
		# Check if all GPUs are still properly recognized
		If ($check_unrecognized -le $timer_unrecognized)
		{
			$global:timer_unrecognized = 0
			GPU_TEST_UNRECOGNIZED
		}

		# Check if the most profitable currency is still the one being mined then switch to it
		If ($check_profitability -le $timer_profitability)
		{
			$global:timer_profitability = 0
			$global:timer_network_hash = 0 # PROFITABILITY contains the function of UPDATE_NETWORK_HASH_RECORDS
			If  (PROFITABILITY ("active") ) {break}
		}
		# Check the network hash at regular intervals to develop a record that can be used to make
		# near-future predictions for profitability. The currently recorded network hash is actually
		# an average for the previously mined block, so having this record allows you to stay slightly
		# ahead of the crowd that rely on the currently reported network hash.
		ElseIf ($check_network_hash -le $timer_network_hash)
		{
			$global:timer_network_hash = 0
			UPDATE_NETWORK_HASH_RECORDS
		}
		
		# Print the index, name, core clock, memory clock, GPU usage, and power draw for each GPU
		If ($check_detailed_activity -le $timer_detailed_activity)
		{
			$global:timer_detailed_activity = 0
			DETAILED_ACTIVITY
		}
		
		# Check if GPU usage indicates that the miner is active (program error due to voltage, OC, server disconnect, difficulty set to 0 etc.)
		If ($check_inactive -le $timer_inactive) 
		{
			$global:timer_inactive = 0
			If (INACTIVE_MINER) {break}
		}
	}
}
