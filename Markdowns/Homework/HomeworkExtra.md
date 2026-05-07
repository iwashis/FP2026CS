# Homework Extra

> This is an additional Lecture homework for at most extra 5 points.

## Representing the Writer Monad in terms of the State Monad

Recall the standard definitions:

```haskell
newtype Writer w a = Writer { runWriter :: (a, w) }
newtype State  s a = State  { runState  :: s -> (a, s) }
```

with the primitive

```haskell
tell :: Monoid w => w -> Writer w ()
```

In what follows, `w` is assumed to be a `Monoid`.

> **Constraints.** You must implement everything from scratch. Do **not** import
> `Control.Monad.Writer`. You may use `Control.Monad.State`, or implement
> `State` yourself as in Homework 05.

1. **The simulation type and its primitives.**

   Define

   ```haskell
   newtype WriterS w a = WriterS { unWriterS :: State w a }
   ```

   and implement

   ```haskell
   tellS       :: Monoid w => w -> WriterS w ()
   runWriterS  :: Monoid w => WriterS w a -> (a, w)
   execWriterS :: Monoid w => WriterS w a -> w
   ```

   subject to the following specification: for every `Writer w a` value `m`,

   ```haskell
   runWriter m == runWriterS (toWriterS m)
   ```

   where `toWriterS` is the conversion defined in part 3.

2. **Functor, Applicative, and Monad instances.**

   Provide the instances

   ```haskell
   instance Functor (WriterS w)
   instance Monoid w => Applicative (WriterS w)
   instance Monoid w => Monad (WriterS w)
   ```

3. **Translation between `Writer` and `WriterS`.**

   Define

   ```haskell
   toWriterS   :: Monoid w => Writer w a  -> WriterS w a
   fromWriterS :: Monoid w => WriterS w a -> Writer w a
   ```

   and state, in a comment, the equations

   ```haskell
   fromWriterS . toWriterS == id
   toWriterS . fromWriterS == id
   ```

   together with their proofs (equational reasoning is sufficient).
