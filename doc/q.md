### Q

An program element; anything that forms a node in the syntax tree
representing a program.

### Q::Expr

An expression; something that can be evaluated to a value.

### Q::Term

A term; a unit of parsing describing a value or an identifier. Along with
operators, what makes up expressions.

### Q::Literal

A literal; a constant value written out explicitly in the program, such as
`nil`, `True`, `5`, or `"James Bond"`.

Compound values such as arrays and objects are considered terms but not
literals.

### Q::Literal::Nil

The `nil` literal.

### Q::Literal::Bool

A boolean literal; either `True` or `False`.

### Q::Literal::Int

An integer literal; a non-negative number.

Negative numbers are not themselves considered integer literals: something
like `-5` is parsed as a `prefix:<->` containing a literal `5`.

### Q::Literal::Str

A string literal.

### Q::Identifier

An identifier; a name which identifies a storage location in the program.

Identifiers are subject to *scoping*: the same name can point to different
storage locations because they belong to different scopes.

### Q::Regex::Fragment

The parent role to all regex fragment types.

### Q::Regex::Str

A regex fragment for a simple string.
Corresponds to the `"..."` regex syntax.

### Q::Regex::Identifier

A regex fragment using a variable from the program.
Corresponds to an identifier in a regex.

### Q::Regex::Call

A regex fragment calling to another regex.
Corresponds to the `<...>` regex syntax.

### Q::Regex::Alternation

An alternation between fragments.

### Q::Regex::Group

A regex fragment containing several other fragments.
Corresponds to the "[" ... "]" regex syntax.

### Q::Regex::OneOrMore

A regex fragment representing the "+" quantifier.

### Q::Regex::ZeroOrMore

A regex fragment representing the "*" quantifier.

### Q::Regex::ZeroOrOne

A regex fragment representing the "?" quantifier.

### Q::Term::Regex

A regular expression (*regex*).

### Q::Term::Array

An array. Array terms consist of zero or more *elements*, each of which
can be an arbitrary expression.

### Q::Term::Tuple

A tuple. Tuple terms consist of zero or more *elements*, each of which
can be an arbitrary expression.

### Q::Term::Object

An object. Object terms consist of an optional *type*, and a property list
with zero or more key/value pairs.

### Q::Property

An object property. Properties have a key and a value.

### Q::PropertyList

A property list in an object. Property lists have zero or more key/value
pairs. Keys in objects are considered unordered, but a property list has
a specified order: the order the properties occur in the program text.

### Q::Declaration

A declaration; something that introduces a name.

### Q::Trait

A trait; a piece of metadata for a routine. A trait consists of an
identifier and an expression.

### Q::TraitList

A list of zero or more traits. Each routine has a traitlist.

### Q::Term::Sub

A subroutine.

### Q::Block

A block. Blocks are used in a number of places: by routines, by
block statements, by other compound statements (such as `if` statements)
and by `quasi` terms and sub terms. Blocks are not, however, terms
in their own regard.

A block has a parameter list and a statement list, each of which can
be empty.

### Q::Prefix

A prefix operator; an operator that occurs before a term, like the
`-` in `-5`.

### Q::Infix

An infix operator; something like the `+` in `2 + 2` that occurs between
two terms.

### Q::Infix::Assignment

An assignment operator. Puts a value in a storage location.

### Q::Infix::Or

A short-circuiting disjunction operator; evaluates its right-hand
side only if the left-hand side is falsy.

### Q::Infix::DefinedOr

A short-circuiting "defined-or" operator. Evaluates its
right-hand side only if the left-hand side is `nil`.

### Q::Infix::And

A short-circuiting "and" operator. Evaluates its
right-hand side only if the left-hand side is truthy.

### Q::Postfix

A postfix operator; something like the `[0]` in `agents[0]` that occurs
after a term.

### Q::Postfix::Index

An indexing operator; returns an array element or object property.
Arrays expect integer indices and objects expect string property names.

### Q::Postfix::Call

An invocation operator; calls a routine.

### Q::Postfix::Property

An object property operator; fetches a property out of an object.

### Q::Unquote

An unquote; allows Qtree fragments to be inserted into places in a quasi.

### Q::Unquote::Prefix

An unquote which is a prefix operator.

### Q::Unquote::Infix

An unquote which is an infix operator.

### Q::Term::Quasi

A quasi; a piece of 007 code which evaluates to that code's Qtree
representation. A way to "quote" code in a program instead of running
it directly in place. Used together with macros.

The term "quasi" comes from the fact that inside the quoted code there
can be parametric holes ("unquotes") where Qtree fragments can be
inserted. Quasiquotation is the practice of combining literal code
fragments with such parametric holes.

### Q::Parameter

A parameter. Any identifier that's declared as the input to a block
is a parameter, including subs, macros, and `if` statements.

### Q::ParameterList

A list of zero or more parameters.

### Q::ArgumentList

A list of zero or more arguments.

### Q::Statement

A statement.

### Q::Term::My

A `my` variable declaration.

### Q::Statement::Expr

A statement consisting of an expression.

### Q::Statement::If

An `if` statement.

### Q::Statement::Block

A block statement.

### Q::CompUnit

A block-level statement representing a whole compilation unit.
We can read "compilation unit" here as meaning "file".

### Q::Statement::For

A `for` loop statement.

### Q::Statement::While

A `while` loop statement.

### Q::Statement::Return

A `return` statement.

### Q::Statement::Throw

A `throw` statement.

### Q::Statement::Sub

A subroutine declaration statement.

### Q::Statement::Macro

A macro declaration statement.

### Q::Statement::BEGIN

A `BEGIN` block statement.

### Q::Statement::Class

A class declaration statement.

### Q::StatementList

A list of zero or more statements. Statement lists commonly occur
directly inside blocks (or at the top level of the program, on the
compunit level). However, it's also possible for a `quasi` to
denote a statement list without any surrounding block.

### Q::Expr::BlockAdapter

An expression which holds a block. Surprisingly, this never
happens in the source code text itself; because of 007's grammar, an
expression can never consist of a block.

However, it can happen as a macro call (an expression) expands into
a block of one or more statements; that's when this Qtype is used.

Semantically, the block is executed normally, and
if execution evaluates the last statement and the statement turns out
to have a value (because it's an expression statement), then this
value is the value of the whole containing expression.

