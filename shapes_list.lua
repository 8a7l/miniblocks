-- MiniBlocks — cut blocks into 21 mini-forms
-- Copyright (C) 2026 Vasyl Onufriichuk
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <https://www.gnu.org/licenses/>.

-- shapes_list.lua
-- 21 унікальна непорожня форма MiniBlocks.
--
-- name — внутрішній ID (використовується в іменах нод і рецептах)
-- mask — 8-бітна маска

miniblocks.shapes = {
	{ name = "1",  mask = 1   },
	{ name = "2",  mask = 3   },
	{ name = "3",  mask = 6   },
	{ name = "4",  mask = 7   },
	{ name = "5",  mask = 22  },
	{ name = "6",  mask = 15  },
	{ name = "7",  mask = 23  },
	{ name = "8",  mask = 24  },
	{ name = "9",  mask = 25  },
	{ name = "10", mask = 27  },
	{ name = "11", mask = 29  },
	{ name = "12", mask = 30  },
	{ name = "13", mask = 31  },
	{ name = "14", mask = 60  },
	{ name = "15", mask = 61  },
	{ name = "16", mask = 63  },
	{ name = "17", mask = 105 },
	{ name = "18", mask = 107 },
	{ name = "19", mask = 111 },
	{ name = "20", mask = 126 },
	{ name = "21", mask = 127 },
}