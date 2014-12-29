{-# LANGUAGE EmptyDataDecls, 
             FlexibleContexts,
             GADTs,
             GeneralizedNewtypeDeriving,
             MultiParamTypeClasses,
             OverloadedStrings,
             DeriveGeneric,
             QuasiQuotes,
             TemplateHaskell,            
             TypeFamilies #-}

module Tables where
    
import           Database.Persist.TH
import Data.Text


data Time = Time { timeField :: [Int] } deriving (Show, Read, Eq)
derivePersistField "Time"

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Courses json
    --department String
    code Text
    title Text
    description Text
    manualTutorialEnrolment Bool Maybe
    --manualPracticalEnrolment Bool
    prereqs Text Maybe
    exclusions Text Maybe
    breadth Int
    distribution Int
    --prep Text
    deriving Show

Lectures
    --department String
    code Text
    session Text
    section Text
    times [Time]
    capacity Int
    enrolled Int
    waitlist Int
    extra Int
    -- location Text -- Location does not exist in JSON files.
    time_str Text
    deriving Show

Tutorials
    --department String
    code Text
    session Text
    tutorial Text
    --times [Time]
    --timeStr Text
    deriving Show

Breadth
    bId Int
    description String
    deriving Show

Distribution
    dId Int
    description String
    deriving Show
|]