-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module Pointer
    exposing
        ( Event(..)
        , Pointer
        , offset
        , movement
        , attributes
        , askTime
        )

{-| This module aims at giving helper functions to deal with pointer events.

@docs Event, Pointer, offset, movement, attributes, askTime
-}

import Html as H exposing (Html)
import Html.Events as HE
import Helpers.Events as HPE
import Tools exposing (Tool)
import Time exposing (Time)
import Task exposing (Task)


{-| Events generated by a pointer device.
-}
type Event
    = Down
    | Move
    | Up
    | Cancel


{-| A Pointer.
-}
type alias Pointer =
    { event : Event
    , offsetX : Float
    , offsetY : Float
    , movementX : Float
    , movementY : Float
    }


{-| Returns (offsetX, offsetY).
-}
offset : Pointer -> ( Float, Float )
offset pointer =
    ( pointer.offsetX, pointer.offsetY )


{-| Returns (movementX, movementY).
-}
movement : Pointer -> ( Float, Float )
movement pointer =
    ( pointer.movementX, pointer.movementY )



-- HTML POINTER ATTRIBUTES ###########################################


{-| Returns a list of attribute messages with useful mouse events listeners.
-}
attributes : (Pointer -> msg) -> Tool -> Maybe Pointer -> List (H.Attribute msg)
attributes msgMaker currentTool previousPointer =
    case currentTool of
        Tools.None ->
            noToolAttributes msgMaker previousPointer

        _ ->
            toolAttributes msgMaker previousPointer


noToolAttributes : (Pointer -> msg) -> Maybe Pointer -> List (H.Attribute msg)
noToolAttributes msgMaker previousPointer =
    [ HPE.movementOn "mousedown" <| msgMaker << (fromOffset Down)
    , HPE.movementOn "mouseup" <| msgMaker << (fromOffset Up)
    ]
        ++ if previousPointer == Nothing then
            []
           else
            [ HPE.movementOn "mousemove" <| msgMaker << (fromMovement Move) ]


toolAttributes : (Pointer -> msg) -> Maybe Pointer -> List (H.Attribute msg)
toolAttributes msgMaker previousPointer =
    [ HPE.offsetOn "mousedown" <| msgMaker << (fromOffset Down)
    , HPE.offsetOn "mouseup" <| msgMaker << (fromOffset Up)
    ]
        ++ if previousPointer == Nothing then
            []
           else
            [ HPE.offsetOn "mousemove" <| msgMaker << (fromOffset Move) ]


fromOffset : Event -> ( Float, Float ) -> Pointer
fromOffset event ( offsetX, offsetY ) =
    { event = event
    , offsetX = offsetX
    , offsetY = offsetY
    , movementX = 0
    , movementY = 0
    }


fromMovement : Event -> ( Float, Float ) -> Pointer
fromMovement event ( movementX, movementY ) =
    { event = event
    , offsetX = 0
    , offsetY = 0
    , movementX = movementX
    , movementY = movementY
    }



-- HTML TIME ATTRIBUTES ##############################################


{-| Use a message maker (tagger) to create a command message giving Time.now.
-}
askTime : (Time -> msg) -> Cmd msg
askTime msgMaker =
    Task.perform identity msgMaker Time.now