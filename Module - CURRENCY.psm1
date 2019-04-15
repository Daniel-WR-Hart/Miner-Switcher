class CURRENCY
{
	# Fixed characteristics
	[String] $name
	[String] $tag
	[String] $algo
	[String] $miner # used to determine how long to wait before checking for inactivity
	[String] $FileName
	[String[]] $Arguments = @()
	
	# Updated every 5 minutes with https://whattomine.com/coins.json
	[float] $block_time # seconds per block
	[float] $block_reward # rewards per block
	[float[]] $net_hash = @()# last 720 current-difficulty reports (Check every minute, history reaching back 12 hours)
	##############[int[]] $net_hash_distribution	#used to calculate the 24h average and distribution network hash
	$net_hash_average
	[float] $predicted_net_hash
	
	[float] $bitcoin_per_currency_24 # average over last 24h, in bitcoin/currency
	[float] $my_reward_in_currency
	[float] $my_reward_in_usd
	
	[float] $my_predicted_reward_in_currency
	[float] $my_predicted_reward_in_usd
	
	function CALCULATE_PROFITABILITY ([PSCustomObject]$coin_stats, [float]$usd_per_bitcoin)
	{
		# $my_reward_in_currency based on: CURRENT network hash rate - AVERAGE PAST 24-HOUR bitcoin/currency exchange rate - AVERAGE PAST 7-DAY USD/bitcoin exchange rate
		
		# Figure out how to get 7-day price average ####################################################################
		
		$block_time = $coin_stats.block_time
		$block_reward = $coin_stats.block_reward
		UPDATE_NETWORK_HASHES ( $coin_stats.nethash )
		PREDICT_NEXT_NETWORK_HASH ( $coin_stats.difficulty, $coin_stats.difficulty24, $coin_stats.nethash )
		$bitcoin_per_currency_24 = $coin_stats.exchange_rate24
		
		If ($algo -eq "Equihash") { $my_hash = $equihash_hash }
		Else If ($algo -eq "NeoScrypt") { $my_hash = $neoscrypt_hash }
		Else If ($algo -eq "LBRY") { $my_hash = $lbry_hash }

		$network_reward_per_day = (86400 * $block_reward) / $block_time		# 86400s in a day
		$hash_ratio = $my_hash / $net_hash[$net_hash.length - 1]
		$predicted_hash_ratio = $my_hash / $predicted_net_hash

		$my_reward_in_currency = $network_reward_per_day * $hash_ratio
		$my_reward_in_usd = $my_reward_in_currency * $bitcoin_per_currency_24 * $usd_per_bitcoin
		
		$my_predicted_reward_in_currency = $network_reward_per_day * $predicted_hash_ratio
		$my_predicted_reward_in_usd = $my_predicted_reward_in_currency * $bitcoin_per_currency_24 * $usd_per_bitcoin
	}
	
	# Only called once from PROFITABILITY()
	# Start the script so that the nethash history looks constant
	function INITIALIZE_NETWORK_HASHES( [[float]$24h_net_hash, float]$latest_net_hash ) #???????????????????????
	{
		# Every array element except the last should start off very close to the actual network has average, only the last one should be current
		For ($i = 0; $i -lt ($hash_record_length - 1); $i++) { $net_hash += $24h_net_hash }
		
		$net_hash += $latest_net_hash
		
		# Make the distribution will start off very average and will need 12 hours to be fully updated
		####################$net_hash_distribution = 0,0,0,($net_hash.length - 1),0,0,0
		
		If ($latest_net_hash 
	}
	
	function UPDATE_NETWORK_HASHES( [float]$latest_net_hash )
	{
		For ($i = 0; $i -lt ($net_hash.length - 1); $i++) { $net_hash[$i] = $net_hash[$i + 1] }
		
		$net_hash[$net_hash.length - 1] = $latest_net_hash
	}
	
	# I suspect that the measured network has is a slightly outdated figure based on the last completed block, so it seems like it would be optimal to mine based on the
	# predicted network hash rates over the next few minutes since I only update my profitability figures once every 5 minutes.
	# In order to mine at the bottom of a nethash dip, you need to start mining slightly before then.
	# I didn't bother recording historical profitability because it probably won't give me any useful information. Higher-than-usual profitability can predict an
	# increase in network hash, but so does a lower-than-usual network has since it inversely correlates to profitability.
	# It's possible for a currency to have an abnormally low network hash and still have low profitability, so for this reason I'm against the approach of increasing
	# the weight of the role of network hash in the profitability calculation as a means to predicting short-term profitability,i.e. substituting $nethash for ($nethash)^(3/2).
	# This approach looks at how the network hash is distributed and predicts that the next net hash will be closer to the average than it already is, and the extent of the change
	# is proportional to how far away it is.
	function PREDICT_NEXT_NETWORK_HASH( $diff, $diff24, $nh )
	{
		# Difficulty is directly correlated to network hash, so if the current difficulty is x% of the 24h average difficulty, roughly the same should be true for the net hash
		$ratio = $diff / $diff24
		$i = $net_hash.length
		
		# If net hash is measured to decrease 3 times in a row
		If ( $net_hash[$i - 4] -gt $net_hash[$i - 3] -and $net_hash[$i - 3] -gt $net_hash[$i - 2] -and $net_hash[$i - 2] -gt $net_hash[$i - 1] )
		{
			# Ranges below 1.000 chosen by taking the inverses of 1.6, 1.5, 1.4 etc.
		
			# The further the nethash is from the average, the more likely it is to move towards the average over the next few minutes
			If		($ratio -gt 1.600) {$predicted_net_hash = $nh * 1.20}
			ElseIf	($ratio -gt 1.500) {$predicted_net_hash = $nh * 1.15}
			ElseIf	($ratio -gt 1.400) {$predicted_net_hash = $nh * 1.10}
			ElseIf	($ratio -gt 1.300) {$predicted_net_hash = $nh * 1.07}
			ElseIf	($ratio -gt 1.200) {$predicted_net_hash = $nh * 1.05}
			ElseIf	($ratio -gt 1.150) {$predicted_net_hash = $nh * 1.02}
			ElseIf	($ratio -gt 1.100) {$predicted_net_hash = $nh * 1.00}
			ElseIf	($ratio -gt 1.050) {$predicted_net_hash = $nh * 0.98}
			ElseIf	($ratio -gt 1.000) {$predicted_net_hash = $nh * 0.96}
			ElseIf	($ratio -gt 0.952) {$predicted_net_hash = $nh * 0.94}
			ElseIf	($ratio -gt 0.909) {$predicted_net_hash = $nh * 0.92}
			ElseIf	($ratio -gt 0.870) {$predicted_net_hash = $nh * 0.90}
			ElseIf	($ratio -gt 0.833) {$predicted_net_hash = $nh * 0.89}
			ElseIf	($ratio -gt 0.769) {$predicted_net_hash = $nh * 0.88}
			ElseIf	($ratio -gt 0.714) {$predicted_net_hash = $nh * 0.87}
			ElseIf	($ratio -gt 0.667) {$predicted_net_hash = $nh * 0.86}
			Else					   {$predicted_net_hash = $nh * 0.85}
		}
		# If net hash is measured to increase 3 times in a row
		ElseIf ( $net_hash[$i - 4] -lt $net_hash[$i - 3] -and $net_hash[$i - 3] -lt $net_hash[$i - 2] -and $net_hash[$i - 2] -lt $net_hash[$i - 1] )
		{
			If		($ratio -gt 1.600) {$predicted_net_hash = $nh * 0.85}
			ElseIf	($ratio -gt 1.500) {$predicted_net_hash = $nh * 0.86}
			ElseIf	($ratio -gt 1.400) {$predicted_net_hash = $nh * 0.87}
			ElseIf	($ratio -gt 1.300) {$predicted_net_hash = $nh * 0.88}
			ElseIf	($ratio -gt 1.200) {$predicted_net_hash = $nh * 0.89}
			ElseIf	($ratio -gt 1.150) {$predicted_net_hash = $nh * 0.90}
			ElseIf	($ratio -gt 1.100) {$predicted_net_hash = $nh * 0.92}
			ElseIf	($ratio -gt 1.050) {$predicted_net_hash = $nh * 0.94}
			ElseIf	($ratio -gt 1.000) {$predicted_net_hash = $nh * 0.96}
			ElseIf	($ratio -gt 0.952) {$predicted_net_hash = $nh * 0.98}
			ElseIf	($ratio -gt 0.909) {$predicted_net_hash = $nh * 1.00}
			ElseIf	($ratio -gt 0.870) {$predicted_net_hash = $nh * 1.02}
			ElseIf	($ratio -gt 0.833) {$predicted_net_hash = $nh * 1.05}
			ElseIf	($ratio -gt 0.769) {$predicted_net_hash = $nh * 1.07}
			ElseIf	($ratio -gt 0.714) {$predicted_net_hash = $nh * 1.10}
			ElseIf	($ratio -gt 0.667) {$predicted_net_hash = $nh * 1.15}
			Else					   {$predicted_net_hash = $nh * 1.20}
		}
		# If there is not straightforward pattern, take the average of the last 4 measurements
		Else
		{
			$predicted_net_hash = ($net_hash[$i - 4] + $net_hash[$i - 3] + $net_hash[$i - 2] + $net_hash[$i - 1]) / 4
		}
	}
	
	
	# PRICE ONLY
	# https://coinmarketcap.com/api/
	# https://cryptocoincharts.info/coins/info
	
	# EXCHANGE RATE CHART, NETWORK HASH CHART, BLOCK REWARD, BLOCK TIME
	# https://www.coinwarz.com/cryptocurrency/coins/zcash
	
	# NETWORK HASH CHART, BLOCK REWARD, BLOCK TIME
	# https://whattomine.com/coins.json
	# https://www.coinchoose.com/coins/zcash/
	
	# POTENTIALLY USEFUL
	# http://coinexchangeio.github.io/slate
	# https://bitcoinaverage.com/
}

function Get-CURRENCY() {
	return [CURRENCY]::new()
}

# Export the function, which can generate a new instance of the class
Export-ModuleMember -Function Get-NewMyClass
