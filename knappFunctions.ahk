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

; try finding a combination that creates no scrap by pulling randomly
fn_knappCombinationOrScrap(param_invetory, param_desired, param_attempts := 3000)
{
	allSets := []
	loop, % 5 {
		setSize := A_Index
		loop, % param_attempts {
			; create random set of inventory
			set := biga.sampleSize(param_invetory, setSize)
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


fn_offByIsPositive(param_value) {
	return param_value.offBy > 0
}


fn_knappOrScrap(param_inventory, param_desired, param_key:="")
{
	outputArr := []
	total := 0
	for key, value in param_inventory {
		remaining := param_desired - lastTotal
		total += value[param_key]
		outputArr.push(param_inventory[key])
		; check if exact total reached
		if (total = param_desired) {
			return outputArr
		}
		; check how much scrap will be created
		if (total > param_desired) {
			scrap := abs(remaining - value[param_key])
			outputArr["scrap"] := scrap
			return outputArr
		}
		lastTotal := total
	}
}