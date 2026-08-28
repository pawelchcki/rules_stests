// Common tools and helper functions
package common

import (
	"bytes"
	"crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"math/big"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
	"github.com/go-playground/validator/v10"
	"github.com/golang-jwt/jwt/v5"
)

var letters = []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

// A helper function to generate random string
func RandString(n int) string {
	b := make([]rune, n)
	for i := range b {
		randIdx, err := rand.Int(rand.Reader, big.NewInt(int64(len(letters))))
		if err != nil {
			panic(err)
		}
		b[i] = letters[randIdx.Int64()]
	}
	return string(b)
}

// A helper function to generate random int
func RandInt() int {
	randNum, err := rand.Int(rand.Reader, big.NewInt(1000000))
	if err != nil {
		panic(err)
	}
	return int(randNum.Int64())
}

// Keep this two config private, it should not expose to open source
const JWTSecret = "A String Very Very Very Strong!!@##$!@#$"      // #nosec G101
const RandomPassword = "A String Very Very Very Random!!@##$!@#4" // #nosec G101

// A Util function to generate jwt_token which can be used in the request header
func GenToken(id uint) string {
	jwt_token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"id":  id,
		"exp": time.Now().Add(time.Hour * 24).Unix(),
	})
	// Sign and get the complete encoded token as a string
	token, err := jwt_token.SignedString([]byte(JWTSecret))
	if err != nil {
		fmt.Printf("failed to sign JWT token for id %d: %v\n", id, err)
		return ""
	}
	return token
}

// The RealWorld error envelope maps each field to a list of messages:
//
//	{"errors": {"email": ["can't be blank"]}}
type CommonError struct {
	Errors map[string][]string `json:"errors"`
}

// To handle the error returned by c.Bind in gin framework.
// The RealWorld contract distinguishes a missing or empty value from one that
// is present but malformed, and names fields by their JSON spelling.
// https://github.com/go-playground/validator/blob/v9/_examples/translations/main.go
func NewValidatorError(err error) CommonError {
	res := CommonError{}
	res.Errors = make(map[string][]string)
	errs, ok := err.(validator.ValidationErrors)
	if !ok {
		res.Errors["body"] = []string{"is invalid"}
		return res
	}
	for _, v := range errs {
		field := strings.ToLower(v.Field())
		message := "is invalid"
		if isBlankValue(v.Value()) {
			message = "can't be blank"
		}
		res.Errors[field] = append(res.Errors[field], message)
	}
	return res
}

func isBlankValue(value interface{}) bool {
	if value == nil {
		return true
	}
	text, ok := value.(string)
	return ok && text == ""
}

// Wrap the error info in the RealWorld envelope
func NewError(key string, err error) CommonError {
	res := CommonError{}
	res.Errors = make(map[string][]string)
	res.Errors[key] = []string{err.Error()}
	return res
}

// SuppliedFields returns the raw JSON of each key present under the request's
// envelope object, leaving the body readable by the validator that follows.
// The contract distinguishes an omitted field from one explicitly set to null,
// which a pre-filled validator cannot tell apart on its own.
func SuppliedFields(c *gin.Context, envelope string) (map[string]json.RawMessage, error) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		return nil, err
	}
	c.Request.Body = io.NopCloser(bytes.NewReader(body))
	if len(bytes.TrimSpace(body)) == 0 {
		return nil, fmt.Errorf("missing %s envelope", envelope)
	}
	var decoded map[string]json.RawMessage
	if err := json.Unmarshal(body, &decoded); err != nil {
		return nil, err
	}
	inner, ok := decoded[envelope]
	if !ok {
		return nil, fmt.Errorf("missing %s envelope", envelope)
	}
	var fields map[string]json.RawMessage
	if err := json.Unmarshal(inner, &fields); err != nil {
		return nil, err
	}
	if fields == nil {
		return nil, fmt.Errorf("missing %s envelope", envelope)
	}
	return fields, nil
}

// IsExplicitNull reports whether the request supplied the field as JSON null.
func IsExplicitNull(fields map[string]json.RawMessage, key string) bool {
	raw, ok := fields[key]
	return ok && string(bytes.TrimSpace(raw)) == "null"
}

// BlankFieldError builds the contract's envelope for fields that may not be
// blanked.
func BlankFieldError(fields ...string) CommonError {
	res := CommonError{Errors: make(map[string][]string)}
	for _, field := range fields {
		res.Errors[field] = []string{"can't be blank"}
	}
	return res
}

// Changed the c.MustBindWith() ->  c.ShouldBindWith().
// I don't want to auto return 400 when error happened.
// origin function is here: https://github.com/gin-gonic/gin/blob/master/context.go
func Bind(c *gin.Context, obj interface{}) error {
	b := binding.Default(c.Request.Method, c.ContentType())
	return c.ShouldBindWith(obj, b)
}
