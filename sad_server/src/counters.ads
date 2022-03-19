generic
   type T is (<>);
package Counters is

   type Counter is tagged private;

   function Next (C : in out Counter) return T;

-- We could take the capacity here and combine our level array, but by splitting it in two we can just do one big malloc.
private
   type Counter is tagged record
      Is_First : Boolean := True;
      Current  : T       := T'First;
   end record;
end Counters;