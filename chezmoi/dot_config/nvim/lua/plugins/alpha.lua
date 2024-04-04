return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	opts = function()
		local dashboard = require("alpha.themes.dashboard")
		local logo = {
			[[       .o.       ooooo        ooooo      ooo ooooo  ]],
			[[      .888.      `888'        `888b.     `8' `888'  ]],
			[[     .8"888.      888          8 `88b.    8   888   ]],
			[[    .8' `888.     888          8   `88b.  8   888   ]],
			[[   .88ooo8888.    888          8     `88b.8   888   ]],
			[[  .8'     `888.   888       o  8       `888   888   ]],
			[[ o88o     o8888o o888ooooood8 o8o        `8  o888o  ]],
		}

		dashboard.section.header.val = logo
		dashboard.section.buttons.val = {
			dashboard.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
			dashboard.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
			dashboard.button(
				"p",
				" " .. " Find project",
				":lua require('telescope').extensions.projects.projects()<CR>"
			),
			dashboard.button("r", " " .. " Recent files", ":Telescope oldfiles <CR>"),
			dashboard.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
			dashboard.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
			dashboard.button("s", "勒" .. " Restore Session", [[:lua require("persistence").load() <cr>]]),
			dashboard.button("l", "鈴" .. " Lazy", ":Lazy<CR>"),
			dashboard.button("q", " " .. " Quit", ":qa<CR>"),
		}
		return dashboard
	end,
}
