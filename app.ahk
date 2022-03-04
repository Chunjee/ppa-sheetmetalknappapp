#NoEnv
#NoTrayIcon
SetBatchLines, -1
#SingleInstance force

#Include html_gui.ahk

#Include %A_ScriptDir%\node_modules
#Include biga.ahk\export.ahk
#Include array.ahk\export.ahk
#Include neutron.ahk\export.ahk

global A := new biga()

; variables
global settings := {}
settings.attempts := 2000

inventory := [{tag: "SM1722", weight: 1000, width: 32}
			, {tag: "SM1723", weight: 2100, width: 32}
			, {tag: "SM1724", weight: 3000, width: 32}
			, {tag: "SM1725", weight: 2500, width: 32}
			, {tag: "SM1726", weight: 6200, width: 32}
			, {tag: "SM1727", weight: 1700, width: 32}
			, {tag: "SM1728", weight: 3700, width: 32}
			, {tag: "SM1729", weight: 400, width: 32}
			, {tag: "SM1730", weight: 900, width: 32}
			, {tag: "SM1731", weight: 2700, width: 20}
			, {tag: "SM1732", weight: 2750, width: 20}]
global sortedInv := A.sortBy(inventory, "weight")

; Create a new NeutronWindow and navigate to main HTML page
neutron := new NeutronWindow()
neutron.Load("gui\index.html")
; Use the Gui method to set a custom label prefix for GUI events.
neutron.Gui("+LabelNeutron")
neutron.Show("w1400 h1000")

; read and parse needed stuff from text
; FileRead, outputVar, % A_ScriptDir "\inventory.json"
; global wordsArr := A.map(strSplit(OutputVar, "`n", "`r"), A.trim)
return


; find button
fn_submit(neutron, event)
{
	; clear gui since this process may take a second or so
	neutron.qs("#ahk_output").innerHTML := ""

	; form will redirect the page by default, but we want to handle the form data ourself.
	event.preventDefault()

	; Use Neutron's GetFormData method to process the form data into a form that is easily accessed
	formData := neutron.GetFormData(event.target)
	; formData
	msgbox, % biga.print(formData)
	; => "filter1":"", "filter2":"", "combineKey":"weight", "desiredAmmount":9001, "acceptableScrap": 100
	; filter1 and 2 will be json formatted

	; filter inventory
	filteredInventory := biga.filter(sortedInv, biga.merge(formData.filter1, formData.filter2))

	suggestions := fn_knappStartWithLarge(sortedInv, formData.desiredAmmount, formData.acceptableScrap, settings.attempts)

	; send to html
	html := gui_generateTable(A.chunk(newCanidatesArrFlat, 5), [1,2,3,4,5], false)
	neutron.qs("#ahk_output").innerHTML := html
	neutron.qs("#ahk_canidatesCount").innerHTML := newCanidatesArrFlat.count() " canidate words"

	; --- letter probablities ---

	html := gui_generateTable(A.chunk(filteredSuggestions, 5), [1,2,3,4,5], false)
	neutron.qs("#ahk_exploreoutput").innerHTML := html
}

; fileInstall all dependencies
fileInstall, gui\index.html, gui\index.html
fileInstall, gui\bootstrap.min.css, gui\bootstrap.min.css
fileInstall, gui\bootstrap.min.js, gui\bootstrap.min.js
fileInstall, gui\jquery.min.js, gui\jquery.min.js

NeutronClose:
exitApp
return

; ------------------
; subroutines
; ------------------


; ------------------
; functions
; ------------------

fn_customCompact(param_arr)
{
	l_obj := {}

	; create
	for key, value in param_arr {
		if (value == "" || value == 0) {
			continue
		}
		l_obj[key] := value
	}
	return l_obj
}

fn_knappStartWithLarge(param_inventory, param_desired, param_acceptablecut := 100, param_attempts := 3000)
{
	; filter inventory by items that almost or could be cut to match
	filteredInv := biga.filter(param_inventory, func("fn_closeMatchWeight").bind(param_desired + param_acceptablecut))
	; sort remaining invetory
	sortedInv := biga.sortBy(filteredInv, "weight")
	; last item is the largest that will also not exceed the order desired
	largestPossible := biga.last(sortedInv)
	; remove the selected item from inventory so it can't be selected again for the next part
	index := biga.findIndex(param_inventory, largestPossible)
	param_inventory.removeAt(index)

	; fill the rest of the order, if needed
	if (param_desired > largestPossible.weight) {
		order := fn_fillOrder(param_inventory, param_desired, largestPossible)
		return order
	}
	return largestPossible
}

fn_fillOrder(param_inventory, param_desired, param_mustuseinv, param_acceptablecut := 100, param_attempts := 3000)
{
	allSets := []
	loop, % 5 {
		setSize := A_Index
		loop, % param_attempts {
			; create random set of inventory
			set := biga.sampleSize(param_inventory, setSize)
			set := biga.concat(set, [param_mustuseinv])
			; get total weight of the inventory
			setWeight := biga.sumBy(set, "weight")
			if (setWeight == param_desired) {
				; return the set if exact match on wieght
				return set
			}
			; save set and total 'off by' ammount
			set["offBy"] := setWeight - param_desired
			allSets.push(set)
		}
	}
	; no exact set found, sort by closest and determine ammount of scrap created
	allSets := biga.sortBy(allSets, "offBy")
	; nemove all negative offby sets
	allSets := biga.filter(allSets, Func("fn_offByIsPositive"))
	; return the set with the least ammount of scrap
	return allSets[1]
}

; filters inventory by size.
fn_closeMatchWeight(param_desired, param_inv)
{
	if (param_desired >= param_inv.weight) {
		return true
	}
}
