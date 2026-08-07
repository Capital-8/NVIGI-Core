-- SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
-- SPDX-License-Identifier: MIT

if os.istarget("windows") then

group "plugins/hwi"
	project "nvigi.plugin.hwi.common"
		kind "SharedLib"
		pluginBasicSetup("hwi/common")
	
		files {
			"./*.h",
			"./*.cpp"
		}

		vpaths { ["impl"] = {"./*.h", "./*.cpp" }}

		includedirs {
			"./"
		}
group ""

end
