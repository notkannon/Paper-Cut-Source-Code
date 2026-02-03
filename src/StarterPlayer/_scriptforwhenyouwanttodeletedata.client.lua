wait(3)

local DSS = game:GetService("DataStoreService")

local DataStorePages = DSS:ListDataStoresAsync()

while true do
	local CurrentStoresPage = DataStorePages:GetCurrentPage()

	for i, DataStoreInfo in pairs(CurrentStoresPage) do
		if DataStoreInfo.DataStoreName ~= "PlayerData" then continue end
		print(DataStoreInfo.DataStoreName)

		local DataStore = DSS:GetDataStore(DataStoreInfo.DataStoreName)
		local KeysPages = DataStore:ListKeysAsync()

		while true do 
			local CurrentKeysPage = KeysPages:GetCurrentPage()

			for j, Key in pairs(CurrentKeysPage) do
				local KeyStore = DataStore:GetAsync(Key.KeyName)

				print("deleting " .. Key.KeyName .. "...")

				DataStore:RemoveAsync(Key.KeyName)
			end

			if KeysPages.IsFinished then break end

			KeysPages:AdvanceToNextPageAsync()
		end
	end

	if DataStorePages.IsFinished then break end

	DataStorePages:AdvanceToNextPageAsync()

	task.wait() --you dont need this line if your data isnt too big
end

print("done deleting data")