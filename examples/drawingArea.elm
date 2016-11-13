-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/


module Main exposing (..)

import Array exposing (Array)
import Html as H exposing (Html)
import Html.App as App
import Html.Events as HE
import Html.Attributes as HA
import Json.Encode as JE
import DrawingArea as Area exposing (DrawingArea)
import Annotation as Ann exposing (Annotation)
import Tools exposing (Tool)
import Pointer exposing (Pointer)
import Image exposing (Image)
import Time exposing (Time)


main =
    App.program
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }



-- MODEL #############################################################


type ZoomVariation
    = ZoomIn
    | ZoomOut


type alias Model =
    { area : DrawingArea
    , current : Maybe ( Int, Annotation )
    , jsonExport : String
    , pointer : Maybe Pointer
    , downOrigin : ( Float, Float )
    , label : String
    }


init : ( Model, Cmd msg )
init =
    Model
        (Area.default
            |> Area.changeBgImage (Just (Image "http://lorempixel.com/200/200" 200 200))
            |> Area.fitImage 0.8
        )
        Nothing
        ""
        Nothing
        ( 0, 0 )
        ""
        ! []



-- UPDATE ############################################################


type Msg
    = NewAnnotation
    | Delete
    | Select (Maybe ( Int, Annotation ))
    | SelectTool Tool
    | ExportAnnotations
    | PointerEvent Pointer
    | Zoom ZoomVariation
    | FitImage
    | ChangeLabel String
    | ApplyLabel
    | StartTime Time
    | StopTime Time


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NewAnnotation ->
            let
                area =
                    Area.createAnnotation model.area

                length =
                    Array.length area.annotations
            in
                -- Select the newly created annotation as the current one.
                { model | area = area, current = Area.getAnnotation (length - 1) area }
                    ! []

        Delete ->
            case model.current of
                Nothing ->
                    model ! []

                Just ( id, annotation ) ->
                    let
                        area =
                            Area.removeAnnotation id model.area

                        -- Select the first annotation as the new current annotation.
                        current =
                            Area.getAnnotation 0 area
                    in
                        { model | area = area, current = current } ! []

        Select maybeItem ->
            { model | current = maybeItem } ! []

        SelectTool tool ->
            { model | area = Area.useTool tool model.area } ! []

        ExportAnnotations ->
            { model
                | jsonExport =
                    JE.encode 0 <| Area.exportSelectionsPaths model.area
            }
                ! []

        PointerEvent pointer ->
            let
                ( downOrigin, timeCmd ) =
                    case pointer.event of
                        Pointer.Down ->
                            ( Pointer.offset pointer
                            , Pointer.askTime StartTime
                            )

                        Pointer.Move ->
                            ( model.downOrigin, Cmd.none )

                        _ ->
                            ( model.downOrigin
                            , Pointer.askTime StopTime
                            )

                ( newCurrent, newArea ) =
                    Area.updateArea downOrigin pointer model.current model.area
            in
                { model
                    | pointer = updatePointer pointer
                    , area = newArea
                    , current = newCurrent
                    , downOrigin = downOrigin
                }
                    ! [ timeCmd ]

        Zoom var ->
            case var of
                ZoomIn ->
                    { model | area = Area.zoomIn model.area } ! []

                ZoomOut ->
                    { model | area = Area.zoomOut model.area } ! []

        FitImage ->
            { model | area = Area.fitImage 0.8 model.area } ! []

        ChangeLabel label ->
            { model | label = label } ! []

        ApplyLabel ->
            updateCurrentAnnotation (Ann.setLabel model.label) model

        StartTime time ->
            updateCurrentAnnotation (Ann.setStartTime <| Just time) model

        StopTime time ->
            updateCurrentAnnotation (Ann.setStopTime <| Just time) model


updateCurrentAnnotation : (Annotation -> Annotation) -> Model -> ( Model, Cmd Msg )
updateCurrentAnnotation modifier model =
    let
        ( current, area ) =
            Area.updateAnnotation modifier model.current model.area
    in
        { model | area = area, current = current } ! []


updatePointer : Pointer -> Maybe Pointer
updatePointer pointer =
    case pointer.event of
        Pointer.Down ->
            Just pointer

        Pointer.Move ->
            Just pointer

        _ ->
            Nothing



-- VIEW ##############################################################


view : Model -> Html Msg
view model =
    H.body []
        [ H.button [ HE.onClick NewAnnotation ] [ H.text "New Annotation" ]
        , H.text " Annotation: "
        , Area.selectAnnotationTag model.area model.current Select
        , H.input [ HA.type' "text", HA.placeholder "Label", HE.onInput ChangeLabel ] []
        , H.button [ HE.onClick ApplyLabel ] [ H.text "Apply Label" ]
        , H.button [ HE.onClick Delete ] [ H.text "Delete" ]
        , H.br [] []
        , H.text " Tool: "
        , Area.selectToolTag model.area SelectTool
        , H.br [] []
        , H.button [ HE.onClick <| Zoom ZoomIn ] [ H.text "Zoom In" ]
        , H.button [ HE.onClick <| Zoom ZoomOut ] [ H.text "Zoom Out" ]
        , H.button [ HE.onClick <| FitImage ] [ H.text "Fit Image" ]
        , H.br [] []
        , H.button [ HE.onClick ExportAnnotations ] [ H.text "Export" ]
        , H.br [] []
        , let
            annotation =
                case model.current of
                    Nothing ->
                        Nothing

                    Just ( id, ann ) ->
                        Just ann
          in
            Area.viewAnnotation
                ((Pointer.attributes PointerEvent model.area.currentTool model.pointer)
                    ++ [ HA.style [ ( "border", "1px solid black" ) ] ]
                )
                annotation
                model.area
        , H.p [] [ H.text model.jsonExport ]
        , H.br [] []
        , H.text (toString model)
        ]
