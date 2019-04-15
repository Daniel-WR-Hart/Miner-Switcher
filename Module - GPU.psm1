class GPU
{
	# [int] $index should correspond to the the location in the array and the order it was found in MAKE_GPU_LIST (NVSMI index)
	# It can be useful for debugging purposes and error catching in case a GPU disconnects
	[int] $index	
	[string] $name
	[float] $power_draw
	[float] $current_power_limit
	[float] $default_power_limit
	[int] $temperature
	[int] $cr_clock
	[int] $mem_clock
	[int[]] $utilization = -1,-1,-1,-1,-1	# Tracks the last 5 recordings (25s) of GPU utilization
	
	# Baseline is 
	[float] $equihash_hash
	[float] $neoscrypt_hash
	[float] $lbry_hash
	
	function UPDATE_UTIL ([int[]] newest)
	{
		For ($u = 0; $u -lt 4; $u++) { utilization[$u] = utilization[$u + 1] }
		utilization[4] = newest
	}
}

function Get-GPU() {
	return [GPU]::new()
}

# Export the function, which can generate a new instance of the class
Export-ModuleMember -Function Get-NewMyClass
