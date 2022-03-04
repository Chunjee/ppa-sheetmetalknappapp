SetBatchLines, -1
#SingleInstance, Force
#NoTrayIcon

#Include %A_ScriptDir%\node_modules
#Include biga.ahk\export.ahk
#Include array.ahk\export.ahk

A := new biga() ; requires https://www.npmjs.com/package/biga.ahk

; variables
inventory := [{tag: "SM1722", weight: 3220, width: 32}
			, {tag: "SM1723", weight: 3260, width: 32}
			, {tag: "SM1724", weight: 3260, width: 32}
			, {tag: "SM1725", weight: 3280, width: 32}
			, {tag: "SM1726", weight: 3280, width: 32}
			, {tag: "SM1727", weight: 3590, width: 32}
			, {tag: "SM1728", weight: 3650, width: 32}
			, {tag: "SM1729", weight: 3350, width: 32}
			, {tag: "SM1730", weight: 3350, width: 32}
			, {tag: "SM1731", weight: 3360, width: 32}
			, {tag: "SM1732", weight: 3310, width: 32}
			, {tag: "SM1733", weight: 3380, width: 32}
			, {tag: "SM1734", weight: 3380, width: 32}
			, {tag: "SM1735", weight: 3180, width: 32}
			, {tag: "SM1736", weight: 3180, width: 32}
			, {tag: "SM1737", weight: 3240, width: 32}]

order := [{width: 1.938, weight: 2300}
		, {width: 2.563, weight: 1400}
		, {width: 3.438, weight: 500}
		, {width: 3.500, weight: 1500}
		, {width: 3.625, weight: 1500}
		, {width: 4.313, weight: 500}
		, {width: 4.875, weight: 2200}
		, {width: 5.063, weight: 500}]

; order := [{width: 1.938, weight: 2300}
; 		, {width: 2.563, weight: 1400}
; 		, {width: 3.438, weight: 500}
; 		, {width: 3.500, weight: 1500}]

; /--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
; \--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
fn_knappShuffle(inventory, order)
return




; /--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; functions
; \--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; try finding a combination that creates no scrap by pulling randomly
fn_knappShuffle(param_inventory, param_order, param_maxRolls := 5)
{
	allSets := []
	while (workingSetFound != true) {
		count := A_Index
		loop, % param_maxRolls {
			; create random set of inventory
			set := biga.sampleSize(param_inventory, A_Index)
			; gather all the different cuts in the order
			cuts := []
			for key, value in param_order {
				cuts.push(value.width)
			}

			; calculate yield on this cut arrangment and inventory
			bladeArrangement := fn_cutShuffle(cuts, set[1].width)
			result := calculateYields(set, bladeArrangement)
			; print("total")
			; print(result)
			combinedResult := biga.cloneDeep(result)
			combinedResult.outputs := fn_combinesimiliarWidths(result.outputs)
			; check if set meets all requirements
			; print(biga.sumBy(combinedResult.totals, "scrapYield"))
			if (fn_checkIfOrderSatisfied(combinedResult, param_order, 5) == true && biga.sumBy(combinedResult.totals, "scrapYield") <= 5) {
				print("FINAL:`n`n")
				print(combinedResult)
				print(bladeArrangement)
				print(set)
				print(biga.sumBy(combinedResult.totals, "scrapYield"))
				break 2
			}
		}
	}
}
return

fn_checkIfOrderSatisfied(param_yields, param_order, param_maxScrap)
{
	for key, value in param_order {
		findable := biga.find(param_yields.outputs, {width: value.width})
		; print("findable")
		if (findable.weight > value.weight) {
			continue
		} else {
			; print(value.width ": " findable.weight " lower than the required " value.weight)
			return false
		}
	}
	return true
}

fn_combinesimiliarWidths(param_result)
{
	simplifiedOut := []
	total := 0

	map := []
	for key, value in param_result {
		if (map[value.width] == "") {
			map[value.width] := value.weight
		} else {
			map[value.width] += value.weight
		}
	}
	for key, value in map {
		simplifiedOut.push({width: key, weight: value})
	}
	return simplifiedOut
}

fn_cutShuffle(param_cuts, param_maxWidth, param_rollnumbers:=1)
{
	uniqCuts := biga.uniq(param_cuts)
	outputCuts := uniqCuts.clone()

	minWidth := param_maxWidth - .07
	loop, % param_rollnumbers {
		totalWidth := 0
		while (biga.sumBy(outputCuts) < param_maxWidth - 0.8) {
			outputCuts.push(biga.sample(uniqCuts))
			if (biga.sumBy(outputCuts) > param_maxWidth - 0.5) {
				outputCuts := []
			}
		}
	}
	return outputCuts
}

calculateYields(param_rolls, param_cuts, param_machinelimit:=0.5) {
	cutYields := []
	totals := []
	for key, value in param_rolls {
		totalWidth := 0
		for key2, value2 in param_cuts {
			cutYields.push({width: value2, weight: (value.weight / value.width) * value2})
			totalWidth += value2
		}
		unusedWidth := value.width - totalWidth
		totalScrap := (value.weight / value.width) * unusedWidth
		totalYield := (value.weight / value.width) * totalWidth
		scrapYield := round((totalScrap / totalYield) * 100, 2)
		totals.push({totalWidth: totalWidth, totalYield: totalYield, scrapWidth: unusedWidth, totalScrap: totalScrap, scrapYield: scrapYield, outputs: cutYields})
	}
	return {totals: totals, outputs: cutYields}
}







; /--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; workflow assistance
; \--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
#Persistent
Print(obj, quote:=False, end:="`n")
{
	static _ := DllCall("AllocConsole"), cout := FileOpen("CONOUT$", "w")
	, escapes := [["``", "``" "``"], ["""", """"""], ["`b", "``b"]
	, ["`f", "``f"], ["`r", "``r"], ["`n", "``n"], ["`t", "``t"]]
	if IsObject(obj) {
		for k in obj
			is_array := k == A_Index
		until !is_array
		cout.Write(is_array ? "[" : "{")
		for k, v in obj {
			cout.Write(A_Index > 1 ? ", " : "")
			is_array ? _ : Print(k, 1, "") cout.Write(": ")
			Print(v, 1, "")
		} return cout.Write(( is_array ? "]" : "}") end), end ? cout.__Handle : _
	} if (!quote || ObjGetCapacity([obj], 1) == "")
		return cout.Write(obj . end), end ? cout.__Handle : _
	for k, v in escapes
		obj := StrReplace(obj, v[1], v[2])
	while RegExMatch(obj, "O)[^\x20-\x7e]", m)
		obj := StrReplace(obj, m[0], Format(""" Chr({:04d}) """, Ord(m[0])))
	return cout.Write("""" obj """" . end), end ? cout.__Handle : _
}

~^s Up::
Reload
