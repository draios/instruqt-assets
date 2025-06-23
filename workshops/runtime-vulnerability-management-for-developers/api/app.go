package main

import (
	"fmt"
	"net/http"

	"github.com/crewjam/saml/samlsp"
)

func hello(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %s!", samlsp.AttributeFromContext(r.Context(), "displayName"))
}

func main() {
	app := http.HandlerFunc(hello)
	http.Handle("/hello", app)
	http.ListenAndServe(":8000", nil)
}
