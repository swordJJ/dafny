// Dafny versions of examples from "Practical Coinduction" by Kozen and Silva.
// The comments in this file explain some things about Dafny and its support for
// co-induction; for a full description, see "Co-induction Simply" by Leino and
// Moskal.

// In Dafny, a co-inductive datatype is declared like an inductive datatype, but
// using the keyword "codatatype" instead of "datatype".  The definition lists the
// constructors of the co-datatype (here, Cons) and has the option of naming
// destructors (here, hd and tl).  Here and in some other signatures, the type
// argument to Stream can be omitted, because Dafny fills it in automatically.

codatatype Stream<A> = Cons(hd: A, tl: Stream)

// --------------------------------------------------------------------------

// A co-predicate is defined as a largest fix-point.
copredicate LexLess(s: Stream<int>, t: Stream<int>)
{
  s.hd <= t.hd &&
  (s.hd == t.hd ==> LexLess(s.tl, t.tl))
}

// A co-lemma is used to establish the truth of a co-predicate.
colemma Theorem1_LexLess_Is_Transitive(s: Stream<int>, t: Stream<int>, u: Stream<int>)
  requires LexLess(s, t) && LexLess(t, u);
  ensures LexLess(s, u);
{
  // Here is the proof, which is actually a body of code.  It lends itself to a
  // simple, intuitive co-inductive reading.  For a theorem this simple, this simple
  // reading is all you need.  To understand more complicated examples, or to see
  // what's actually going on under the hood, it's best to read the "Co-induction
  // Simply" paper.
  if s.hd == u.hd {
    Theorem1_LexLess_Is_Transitive(s.tl, t.tl, u.tl);
  }
}

// The following predicate captures the (inductively defined) negation of (the
// co-inductively defined) LexLess above.
predicate NotLexLess(s: Stream<int>, t: Stream<int>)
{
  exists k: nat :: NotLexLess'(k, s, t)
}
predicate NotLexLess'(k: nat, s: Stream<int>, t: Stream<int>)
{
  if k == 0 then false else
    !(s.hd <= t.hd) || (s.hd == t.hd && NotLexLess'(k-1, s.tl, t.tl))
}

lemma EquivalenceTheorem(s: Stream<int>, t: Stream<int>)
  ensures LexLess(s, t) <==> !NotLexLess(s, t);
{
  if !NotLexLess(s, t) {
    EquivalenceTheorem0(s, t);
  }
  if LexLess(s, t) {
    EquivalenceTheorem1(s, t);
  }
}
colemma EquivalenceTheorem0(s: Stream<int>, t: Stream<int>)
  requires !NotLexLess(s, t);
  ensures LexLess(s, t);
{
  // Here, more needs to be said about the way Dafny handles co-lemmas.
  // The way a co-lemma establishes a co-predicate is to prove, by induction,
  // that all finite unrollings of the co-predicate holds.  The unrolling
  // depth is specified using an implicit parameter _k to the co-lemma.
  EquivalenceTheorem0_Lemma(_k, s, t);
}
// The following lemma is an ordinary inductive lemma.  The syntax ...#[...]
// indicates a finite unrolling of a co-inductive predicate.  In particular,
// LexLess#[k] refers to k unrollings of LexLess.
lemma EquivalenceTheorem0_Lemma(k: nat, s: Stream<int>, t: Stream<int>)
  requires !NotLexLess'(k, s, t);
  ensures LexLess#[k](s, t);
{
  // This simple inductive proof is done completely automatically by Dafny.
}
lemma EquivalenceTheorem1(s: Stream<int>, t: Stream<int>)
  requires LexLess(s, t);
  ensures !NotLexLess(s, t);
{
  // The forall statement in Dafny is used, here, as universal introduction:
  // what EquivalenceTheorem1_Lemma establishes for one k, the forall
  // statement establishes for all k.
  forall k: nat {
    EquivalenceTheorem1_Lemma(k, s, t);
  }
}
lemma EquivalenceTheorem1_Lemma(k: nat, s: Stream<int>, t: Stream<int>)
  requires LexLess(s, t);
  ensures !NotLexLess'(k, s, t);
{
}

lemma Theorem1_Alt(s: Stream<int>, t: Stream<int>, u: Stream<int>)
  requires NotLexLess(s, u);
  ensures NotLexLess(s, t) || NotLexLess(t, u);
{
  forall k: nat | NotLexLess'(k, s, u) {
    Theorem1_Alt_Lemma(k, s, t, u);
  }
}
lemma Theorem1_Alt_Lemma(k: nat, s: Stream<int>, t: Stream<int>, u: Stream<int>)
  requires NotLexLess'(k, s, u);
  ensures NotLexLess'(k, s, t) || NotLexLess'(k, t, u);
{
}

function PointwiseAdd(s: Stream<int>, t: Stream<int>): Stream<int>
{
  Cons(s.hd + t.hd, PointwiseAdd(s.tl, t.tl))
}

colemma Theorem2_Pointwise_Addition_Is_Monotone(s: Stream<int>, t: Stream<int>, u: Stream<int>, v: Stream<int>)
  requires LexLess(s, t) && LexLess(u, v);
  ensures LexLess(PointwiseAdd(s, u), PointwiseAdd(t, v));
{
  // The co-lemma will establish the co-inductive predicate by establishing
  // all finite unrollings thereof.  Each finite unrolling is proved by
  // induction, and this induction is performed automatically by Dafny.  Thus,
  // the proof of this co-lemma is trivial (that is, the body of the co-lemma
  // is empty).
}

// --------------------------------------------------------------------------

// The declaration of an (inductive or co-inductive) datatype in Dafny automatically
// gives rise to the declaration of a discriminator for each constructor.  The name
// of such a discriminator is the name of the constructor plus a question mark (that
// is, the question mark is part of the identifier that names the discriminator).
// For example, the boolean expression r.Arrow? returns whether or not a RecType r
// has been constructed by the Arrow constructor.  One can of course also use a
// match expression or match statement for this purpose, but for whatever reason, I
// didn't do so in this file.  Note that the precondition of the access r.dom is
// r.Arrow?.  Also, for a parameter-less constructor like Bottom, a use of the
// discriminator like r.Bottom? is equivalent to r == Bottom.
codatatype RecType = Bottom | Top | Arrow(dom: RecType, ran: RecType)

copredicate Subtype(a: RecType, b: RecType)
{
  a == Bottom ||
  b == Top ||
  (a.Arrow? && b.Arrow? && Subtype(b.dom, a.dom) && Subtype(a.ran, b.ran))
}

colemma Theorem3_Subtype_Is_Transitive(a: RecType, b: RecType, c: RecType)
  requires Subtype(a, b) && Subtype(b, c);
  ensures Subtype(a, c);
{
  if a == Bottom || c == Top {
    // done
  } else {
    Theorem3_Subtype_Is_Transitive(c.dom, b.dom, a.dom);
    Theorem3_Subtype_Is_Transitive(a.ran, b.ran, c.ran);
  }
}

// --------------------------------------------------------------------------

// Closure Conversion

type Const    // uninterpreted type (the details are not important here)
type Var(==)  // uninterpreted type that supports equality
datatype Term = TermConst(Const) | TermVar(Var) | TermAbs(abs: LambdaAbs)
datatype LambdaAbs = Fun(v: Var, body: Term)
codatatype Val = ValConst(Const) | ValCl(cl: Cl)
codatatype Cl = Closure(abs: LambdaAbs, env: ClEnv)
codatatype ClEnv = ClEnvironment(m: map<Var, Val>)  // The built-in Dafny "map" type denotes finite maps

copredicate ClEnvBelow(c: ClEnv, d: ClEnv)
{
  // The expression "y in c.m" says that y is in the domain of the finite map
  // c.m.
  forall y :: y in c.m ==> y in d.m && ValBelow(c.m[y], d.m[y])
}
copredicate ValBelow(u: Val, v: Val)
{
  (u.ValConst? && v.ValConst? && u == v) ||
  (u.ValCl? && v.ValCl? && u.cl.abs == v.cl.abs && ClEnvBelow(u.cl.env, v.cl.env))
}

colemma Theorem4a_ClEnvBelow_Is_Transitive(c: ClEnv, d: ClEnv, e: ClEnv)
  requires ClEnvBelow(c, d) && ClEnvBelow(d, e);
  ensures ClEnvBelow(c, e);
{
  forall y | y in c.m {
    Theorem4b_ValBelow_Is_Transitive#[_k-1](c.m[y], d.m[y], e.m[y]);
  }
}
colemma Theorem4b_ValBelow_Is_Transitive(u: Val, v: Val, w: Val)
  requires ValBelow(u, v) && ValBelow(v, w);
  ensures ValBelow(u, w);
{
  if u.ValCl? {
    Theorem4a_ClEnvBelow_Is_Transitive(u.cl.env, v.cl.env, w.cl.env);
  }
}

datatype Capsule = Cap(e: Term, s: map<Var, ConstOrAbs>)
datatype ConstOrAbs = CC(c: Const) | AA(abs: LambdaAbs)

predicate IsCapsule(cap: Capsule)
{
  cap.e.TermAbs?
}

function ClosureConversion(cap: Capsule): Cl
  requires IsCapsule(cap);
{
  Closure(cap.e.abs, ClosureConvertedMap(cap.s))
  // In the Kozen and Silva paper, there are more conditions, having to do with free variables,
  // but, apparently, they don't matter for the theorems being proved here.
}
function ClosureConvertedMap(s: map<Var, ConstOrAbs>): ClEnv
{
  // The following line uses a map comprehension.  In the notation "map y | D :: E",
  // D constrains the domain of the map to be all values of y satisfying D, and
  // E says what a y in the domain maps to.
  ClEnvironment(map y: Var | y in s :: if s[y].AA? then ValCl(Closure(s[y].abs, ClosureConvertedMap(s))) else ValConst(s[y].c))
}

predicate CapsuleEnvironmentBelow(s: map<Var, ConstOrAbs>, t: map<Var, ConstOrAbs>)
{
  forall y :: y in s ==> y in t && s[y] == t[y]
}

colemma Theorem5_ClosureConversion_Is_Monotone(s: map<Var, ConstOrAbs>, t: map<Var, ConstOrAbs>)
  requires CapsuleEnvironmentBelow(s, t);
  ensures ClEnvBelow(ClosureConvertedMap(s), ClosureConvertedMap(t));
{
}

// --------------------------------------------------------------------------

// The following defines, co-inductively, a relation on streams.  The syntactic
// shorthand in Dafny lets us omit the type parameter to Bisim and the (same)
// type arguments in the types of s and t.  If we want to write this explicitly,
// we would write:
//    copredicate Bisim<A>(s: Stream<A>, t: Stream<A>)
// which is equivalent.  (Being able to omit the arguments reduces clutter.  Note,
// in a similar way, if one tells a colleague about Theorem 6, one can either
// say the explicit "Bisim on A-streams is a symmetric relation" or, since the
// A in that sentence is not used, "Bisim on streams is a symmetric relation".)
copredicate Bisim(s: Stream, t: Stream)
{
  s.hd == t.hd && Bisim(s.tl, t.tl)
}

colemma Theorem6_Bisim_Is_Symmetric(s: Stream, t: Stream)
  requires Bisim(s, t);
  ensures Bisim(t, s);
{
  // proof is automatic
}

function merge(s: Stream, t: Stream): Stream
{
  Cons(s.hd, merge(t, s.tl))
}
// SplitLeft and SplitRight are defined in terms of each other.  Because the
// call to SplitRight in the body of SplitLeft is an argument to a co-constructor,
// Dafny treats the call as a co-recurvie call.  A consequence of this is that
// there is no proof obligation to show termination for that call.  However, the
// call from SplitRight back to SplitLeft is an ordinary (mutually) recursive
// call, and hence Dafny checks termination for it.  Dafny has some simple
// heuristics, based on the types of the arguments of a call, for trying to
// prove termination.  In this case, the type is a co-datatype, for which Dafny
// does not define any useful well-founded order.  Instead, the termination
// argument needs to be supplied explicitly in terms of a metric, rank, variant
// function, or whatever you want to call it--"decreases" clause in Dafny.  In
// this case, Dafny will use a "decreases \top" for SplitRight ("\top" is not
// concrete syntax; I'm using it here just as an illustration).  From this,
// Dafny can prove termination, because the (arbitrary non-\top) value 0 of
// the callee is smaller than the "\top" of the caller.  (Hm, it seems that
// Dafny could be modified to detect this case automatically.)
function SplitLeft(s: Stream): Stream
  decreases 0;
{
  Cons(s.hd, SplitRight(s.tl))
}
function SplitRight(s: Stream): Stream
{
  SplitLeft(s.tl)
}

colemma Theorem7_Merge_Is_Left_Inverse_Of_Split_Bisim(s: Stream)
  ensures Bisim(merge(SplitLeft(s), SplitRight(s)), s);
{
  var LHS := merge(SplitLeft(s), SplitRight(s));
  // The construct that follows is a "calc" statement.  It gives a way to write an
  // equational proof.  Each line in the calculation is an expression that, on
  // behalf of the given hint, is equal to the next line of the calculation.  In
  // the first such step below, the hint is omitted (there's just an English
  // comment, but Dafny ignores it, of course).  In the next two steps, the hint
  // is itself a calculation.  In the last step, the hint is an invocation of
  // the co-inductive hypothesis--that is, it is a call of the co-lemma itself.
  calc {
    Bisim#[_k](LHS, s);  // when all comes around, this is our proof goal:  Bisim unrolled _k times (where _k > 0)
  ==  // def. Bisim (more precisely, def. Bisim#[_k] in terms of Bisim#[_k-1])
    LHS.hd == s.hd && Bisim#[_k-1](LHS.tl, s.tl);
  == calc {  // the left conjunct is easy to establish, so let's do that now
       LHS.hd;
       == merge(SplitLeft(s), SplitRight(s)).hd;
       == SplitLeft(s).hd;
       == s.hd;
     }
    Bisim#[_k-1](LHS.tl, s.tl);
  == calc {  // let us massage the formula LHS.tl
       LHS.tl;
       == merge(SplitLeft(s), SplitRight(s)).tl;
       == merge(SplitRight(s), SplitLeft(s).tl);
       == merge(SplitLeft(s.tl), SplitRight(s.tl));
     }
    Bisim#[_k-1](merge(SplitLeft(s.tl), SplitRight(s.tl)), s.tl);  // this is the hypothesis on s.tl
  == { Theorem7_Merge_Is_Left_Inverse_Of_Split_Bisim(s.tl); }
    true;
  }
}

colemma Theorem7_Merge_Is_Left_Inverse_Of_Split_Equal(s: Stream)
  ensures merge(SplitLeft(s), SplitRight(s)) == s;
{
  // The proof of this co-lemma is actually done completely automatically (so the
  // body of this co-lemma can be empty).  However, just to show what the calculations
  // would look like in a hand proof, here they are:
  calc {
    merge(SplitLeft(s), SplitRight(s)).hd;
  ==
    SplitLeft(s).hd;
  ==
    s.hd;
  }
  calc {
    merge(SplitLeft(s), SplitRight(s)).tl;
  ==
    merge(SplitRight(s), SplitLeft(s).tl);
  ==
    merge(SplitLeft(s.tl), SplitRight(s.tl));
  ==#[_k-1]  { Theorem7_Merge_Is_Left_Inverse_Of_Split_Equal(s.tl); }
    s.tl;
  }
}