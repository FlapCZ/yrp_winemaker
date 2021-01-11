$(document).keyup(function(e) {
	if (e.key === "Escape") {
	  $.post('http://yrp_winemaker/CloseYRPdrugs', JSON.stringify({}));
 }
});
$(document).ready(function() {
	window.addEventListener('message', function(event) {
		var item = event.data;
		if (item.yrp_jobs == true) {
            $('.package').css('display', 'none');
			$('body').css('display', 'block');
            $('.craft').css('display', 'block');
            $('.raisin').css('display', 'block');
            $('.red_raisin').css('display', 'block');
            $('.must_buy').css('display', 'block');
        } else if (item.yrp_see_raisin == true) {
            $('.raisin').css('display', 'none');
            $('.red_raisin').css('display', 'none');
            $('.must_buy').css('display', 'none');
            $('.raisin-info').css('display', 'block');
        } else if (item.yrp_see_red_raisin == true) {
            $('.raisin').css('display', 'none');
            $('.red_raisin').css('display', 'none');
            $('.must_buy').css('display', 'none');
            $('.red_raisin-info').css('display', 'block');
        } else if (item.yrp_see_raisin_c == true) {
            $('.raisin').css('display', 'none');
            $('.red_raisin').css('display', 'none');
            $('.must_buy').css('display', 'none');
            $('.raisin-pack').css('display', 'block');
        } else if (item.yrp_see_redraisin_c == true) {
            $('.raisin').css('display', 'none');
            $('.red_raisin').css('display', 'none');
            $('.must_buy').css('display', 'none');
            $('.red_raisin-pack').css('display', 'block');
		} else if (item.yrp_jobs_package == true) {
            $('.craft').css('display', 'none');
			$('body').css('display', 'block');
            $('.package').css('display', 'block');
            $('.raisin').css('display', 'block');
            $('.red_raisin').css('display', 'block');
            $('.must_buy').css('display', 'block');
        } else if (item.yrp_jobs_sell == true) {
            $('.craft').css('display', 'none');
            $('.package').css('display', 'none');
			$('body').css('display', 'block');
            $('.sell').css('display', 'block');
            $('.raisin').css('display', 'block');
            $('.red_raisin').css('display', 'block');
            $('.must_buy').css('display', 'block');
        } else if (item.yrp_all_close == true) {
            $('body').css('display', 'none');
            $('.craft').css('display', 'none');
            $('.package').css('display', 'none');
            $('.raisin-info').css('display', 'none');
            $('.red_raisin-info').css('display', 'none');
            $('.raisin-pack').css('display', 'none');
            $('.red_raisin-pack').css('display', 'none');
            $('.must_buy').css('display', 'none');
        } else if (item.yrp_back_pack == true) {
            $('.raisin').css('display', 'block');
            $('.red_raisin').css('display', 'block');
            $('.must_buy').css('display', 'block');
            $('.raisin-pack').css('display', 'none');
            $('.red_raisin-pack').css('display', 'none');
        } else if (item.yrp_back_pack_il == true) {
            $('.raisin').css('display', 'block');
            $('.raisin-pack').css('display', 'none');
            $('.red_raisin-pack').css('display', 'none');
        } else if (item.yrp_back_craft == true) {
            $('.raisin').css('display', 'block');
            $('.red_raisin').css('display', 'block');
            $('.must_buy').css('display', 'block');
            $('.raisin-info').css('display', 'none');
            $('.red_raisin-info').css('display', 'none');
        } else if (item.yrp_back_craft_il == true) {
            $('.raisin').css('display', 'block');
            $('.raisin-info').css('display', 'none');
            $('.red_raisin-info').css('display', 'none');
		}
	});

	$(".offnui").click(function() {
        $.post('http://yrp_winemaker/CloseYRPdrugs', JSON.stringify({}));
    });

    $(".back").click(function() {
        $.post('http://yrp_winemaker/BackToPackage', JSON.stringify({}));
    });

    $(".back2").click(function() {
        $.post('http://yrp_winemaker/BackToCrafting', JSON.stringify({}));
    });
    
    $(".SeeRaisinCraft").click(function() {
        $.post('http://yrp_winemaker/SeeRaisinCraft', JSON.stringify({}));
    });

    $(".SeeRedRaisinCraft").click(function() {
        $.post('http://yrp_winemaker/SeeRedRaisinCraft', JSON.stringify({}));
    });

    $(".SeeRaisinPackage").click(function() {
        $.post('http://yrp_winemaker/SeeRaisinPackage', JSON.stringify({}));
    });

    $(".SeeRedRaisinPackage").click(function() {
        $.post('http://yrp_winemaker/SeeRedRaisinPackage', JSON.stringify({}));
    });

	$(".CraftRaisin").click(function () {
		let inputValue = $(".InputRaisin").val()
        if (!inputValue) {
            $.post("http://yrp_winemaker/Notification", JSON.stringify({
                text: "Nelze vycraftit 0 kusů"
            }))
            return
        }
        $.post('http://yrp_winemaker/CraftRaisin', JSON.stringify({
            raisin: inputValue,
		}));
        return;
    })

    $(".CraftRedRaisin").click(function () {
		let inputValue = $(".InputRedRaisin").val()
        if (!inputValue) {
            $.post("http://yrp_winemaker/Notification", JSON.stringify({
                text: "Nelze vycraftit 0 kusů"
            }))
            return
        }
        $.post('http://yrp_winemaker/CraftRedRaisin', JSON.stringify({
            red_raisin: inputValue,
		}));
        return;
    })

    $(".PackageRaisin").click(function () {
		let inputValue = $(".InputPackageRaisin").val()
        if (!inputValue) {
            $.post("http://yrp_winemaker/Notification", JSON.stringify({
                text: "Nelze zabalit 0 kusů"
            }))
            return
        }
        $.post('http://yrp_winemaker/PackageRaisin', JSON.stringify({
            packraisin: inputValue,
		}));
        return;
    })
    
    $(".PackageRedRaisin").click(function () {
		let inputValue = $(".InputPackageRedRaisin").val()
        if (!inputValue) {
            $.post("http://yrp_winemaker/Notification", JSON.stringify({
                text: "Nelze zabalit 0 kusů"
            }))
            return
        }
        $.post('http://yrp_winemaker/PackageRedRaisin', JSON.stringify({
            packraisin: inputValue,
		}));
        return;
    })
    
    $(".SellRaisin").click(function () {
		let inputValue = $(".InputSellRaisin").val()
        if (!inputValue) {
            $.post("http://yrp_winemaker/Notification", JSON.stringify({
                text: "Nelze zabalit 0 kusů"
            }))
            return
        }
        $.post('http://yrp_winemaker/SellRaisin', JSON.stringify({
            packraisin: inputValue,
		}));
        return;
    })

    $(".SellRedRaisin").click(function () {
		let inputValue = $(".InputSellRedRaisin").val()
        if (!inputValue) {
            $.post("http://yrp_winemaker/Notification", JSON.stringify({
                text: "Nelze zabalit 0 kusů"
            }))
            return
        }
        $.post('http://yrp_winemaker/SellRedRaisin', JSON.stringify({
            packraisin: inputValue,
		}));
        return;
    })

})

let scale = 0;
const cards = Array.from(document.getElementsByClassName("job"));
const inner = document.querySelector(".inner");

function slideAndScale() {
cards.map((card, i) => {
	card.setAttribute("data-scale", i + scale);
	inner.style.transform = "translateX(" + scale * 8.5 + "em)";
});
}

(function init() {
slideAndScale();
cards.map((card, i) => {
	card.addEventListener("click", () => {
		const id = card.getAttribute("data-scale");
		if (id !== 2) {
			scale -= id - 2;
			slideAndScale();
		}
	}, false);
});
})();

