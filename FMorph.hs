{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE TypeFamilies              #-}

module FMorph (
        linspace, remap, lerpPts, 
        rotatePts, squarify, randPts, 
        squiggly, squigglify, fuzzify, 
        project2D, scalePts, singlePoint,
        draw, drawShape, play
    ) where 

import Data.Active
import Diagrams.Prelude
import Diagrams.Backend.Cairo
import Diagrams.Animation
import Data.Tuple
import System.Random


--- Constants ---
singlePoint = circle 0.9 # fc black
baseSpeed = 0.3


--- Transformations and effects ---
scalePts r points = map (unr2.(*r).r2) points
project2D scalars = zip scalars $ repeat 0.0


linspace num = map (/num) [0..num]

remap x a b c d     = fst $ unr2 $ 
                                lerp ((x - a)/(b - a)) (r2 (d,0)) (r2 (c,0))
lerpPts amt points1 points2 = map unr2 $ 
                                zipWith (lerp amt) (map r2 points2) (map r2 points1)


rotate'   ang (x,y)  = ((cos ang)*x - (sin ang)*y, (sin ang)*x + (cos ang)*y)
rotatePts ang points = map (rotate' ang) points

foo small' big' = ((remap (abs small') (-c') c' (-side) side) * signum small', 
                   side * signum big')
    where   c' = 100*(cos (pi/4.0))
            side = 100
squarify'(x,y)  =  if abs x < abs y then foo x y else swap $ foo y x
squarify points = map squarify' points

squigglify' rad' nSquiggles amp x = (radS*cos(2*pi*x), radS*sin(2*pi*x))
    where   radS = rad' + amp*(cos(nSquiggles*ang)) -- radius dependent on angle
            ang   = 2*pi*x
squigglify rad' nSquiggles amp points = map (squigglify' rad' nSquiggles amp) points
squiggly   rad' nSquiggles amp numPts = squigglify rad' nSquiggles amp $ 
                                        project2D $ linspace numPts

randScalars n rgen = take n $ randomRs (0,1) rgen :: [Double]
randPts     n rgen = zip (take n $ randScalars (2*n::Int) rgen) 
                         (drop n $ randScalars (2*n::Int) rgen) 

fuzzify' xamp yamp (x,y) (rx,ry) = (x + xamp*rx, y + yamp*ry)
fuzzifyR xamp yamp rands points  = zipWith (fuzzify' xamp yamp) points rands 
fuzzify  xamp yamp rgen  points  = fuzzifyR xamp yamp (randPts (length points) rgen) points 


---   ---
lerpShots   t (shotx, shoty) = draw $ lerpPts t shotx shoty
mkScene speed shotPair = ((pure $ (flip lerpShots) shotPair) <*> stretch (baseSpeed*speed) ui)
                               :: Animation B V2 Double


drawShape ptShape points  = atPoints (map p2 points) $ repeat ptShape
draw = drawShape singlePoint

getShots  xs = map fst xs
getSpeeds xs = map snd xs

play      xs = movie $ zipWith ($)
            (map mkScene $ getSpeeds $ init xs)
            $ zip (getShots $ init xs) (getShots $ tail xs)
