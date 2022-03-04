// on reset button click
$("#reset").click(function(event) {
	$(this).closest('form').find("input").val("");
});
