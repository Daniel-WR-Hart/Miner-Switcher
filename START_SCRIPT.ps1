[int] $gpu_quantity = 1

#My Windows PCs are named GILFOYLE-n, where n is a whole number
[int] $pc_num = "$env:computername" -replace'GILFOYLE-',''

Start-Process powershell -verb runas -ArgumentList "'./MINER_SWITCHER.ps1' -gpu_quantity $gpu_quantity -pc_num $pc_num"
 
