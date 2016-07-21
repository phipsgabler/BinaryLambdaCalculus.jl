-- (almost) original code from https://arxiv.org/pdf/1511.05334v1.pdf

data Term = Index Int
          | Abs Term
          | App Term Term deriving Show
                                   

iv b = if b then 1 else 0

trompTab :: [[Integer]]
trompTab = [0, 0..] : [0, 0..] : [[iv (n-2 < m)
                                   + trompTab !! (n-2) !! (m+1)
                                   + s n m
                                   | m <- [0..]]
                                  | n <- [2..]]
  where s n m = let ti = [trompTab !! i !! m | i <- [0..(n-2)]]
                in sum $ zipWith (*) ti (reverse ti)

tromp m n = trompTab !! n !! m


unrankT :: Int -> Int -> Integer -> Term
unrankT m n k
  | m >= n-1 && k == (tromp m n) = Index (n-1)              -- terms 1^{n-1}0
  | k <= (tromp (m+1) (n-2)) = Abs (unrankT (m+1) (n-2) k)  -- terms 00M
  | otherwise = unrankApp (n-2) 0 (k - tromp (m+1) (n-2))   -- terms 01MN
  where unrankApp n j r
          | r <= tmjtmnj  = let (dv, rm) = (r-1) `divMod` tmnj
                            in App (unrankT m j (dv+1)) (unrankT m (n-j) (rm+1))
          | otherwise = unrankApp n (j+1) (r-tmjtmnj)
          where tmnj = tromp m (n-j)
                tmjtmnj = (tromp m j) * tmnj

unrank m n k | k > tromp m n = Nothing
             | otherwise = Just $ unrankT m n k
