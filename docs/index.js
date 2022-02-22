
let MQ = MathQuill.getInterface(2);

Array.from(document.querySelectorAll(".equation")).forEach(eqn => {
    let content = eqn.innerText;
    let mathField = MQ.MathField(eqn, {
        //autoOperatorNames: "pi theta"
        //spaceBehavesLikeTab: true, // configurable
        // handlers: {
        //   edit: function() { // useful event handlers
        //     latexSpan.textContent = mathField.latex(); // simple API
        //   }
        // }
    });
    mathField.latex(content);
});

Array.from(document.querySelectorAll(".collapsible")).forEach(div => {
    div.style.display = "none";
    let collapser = document.createElement("button");
    collapser.className = "collapser";
    let expanded = false;
    collapser.onclick = () => {
        expanded = !expanded;
        if (expanded) {
            div.style.display = "";
            collapser.style.background = "#363636";
        } else {
            div.style.display = "none";
            collapser.style.background = "";
        }
    }
    let header = div.previousElementSibling;
    let headerText = header.innerText;
    header.innerText = "";
    collapser.innerText = headerText;
    header.appendChild(collapser);
});

document.getElementById("expand-all").onclick = function () {
    Array.from(document.querySelectorAll(".collapsible")).forEach(div => {
        div.style.display = "";
    });
    Array.from(document.querySelectorAll(".collapser")).forEach(collapser => {
        collapser.style.background = "#363636";
    });
}
document.getElementById("collapse-all").onclick = function () {
    Array.from(document.querySelectorAll(".collapsible")).forEach(div => {
        div.style.display = "none";
    });
    Array.from(document.querySelectorAll(".collapser")).forEach(collapser => {
        collapser.style.background = "";
    });
}
