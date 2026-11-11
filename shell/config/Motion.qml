pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property bool isReduced: Config.data.motion.reduced
    property bool isHeld: false
    readonly property int stateDuration: 220
    readonly property QtObject press: QtObject {
        readonly property int down: 80
        readonly property real button: 0.86
        readonly property real tile: 0.9
        readonly property real card: 0.96
        readonly property real glyph: 0.84
        readonly property real task: 0.88
        readonly property real raise: 1.06
    }
    readonly property int hoverIn: 120
    readonly property int hoverOut: 150

    readonly property QtObject pill: QtObject {
        readonly property int pop: 60
        readonly property int spread: 110
        readonly property int spreadDelay: 20
        readonly property int element: 140
        readonly property int leaveElement: 160
        readonly property int leaveWindow: 55
        readonly property int leaveSpread: 105
        readonly property int leavePop: 130
        readonly property int sling: 200
        readonly property int slingIn: 240
        readonly property int slingLead: 90
        readonly property real slingBack: 2.4
        readonly property real slingSpin: -120
        readonly property int gatherRetract: 150
        readonly property int awayHold: leaveWindow / 2 + sling + 20
        readonly property int fold: 105
        readonly property int elementStagger: 28
        readonly property int slide: 160
        readonly property int sizeFollow: 210
    }

    readonly property QtObject sweep: QtObject {
        readonly property int grow: 420
        readonly property int retract: 500
        readonly property int leave: 300
    }

    readonly property QtObject highlight: QtObject {
        readonly property int slide: 240
        readonly property int trail: 60
    }

    readonly property QtObject activity: QtObject {
        readonly property int spread: 200
        readonly property int expand: 380
        readonly property int shrink: 170
        readonly property int shrinkDelay: 60
        readonly property int lag: 60
        readonly property real overshoot: 1.7
        readonly property real arriveShare: 0.55
        readonly property int faceEnter: 140
        readonly property int faceLeave: 90
        readonly property int stagger: 40
        readonly property int satelliteEnter: 240
        readonly property real dropStart: 0.6
        readonly property int bars: 900
        readonly property real barRest: 0.25
        readonly property real barOffset: 0.3
        readonly property int tick: 1000
    }

    readonly property QtObject alerts: QtObject {
        readonly property int grow: 300
        readonly property int shrink: 170
        readonly property int shrinkDelay: 60
        readonly property int lag: 40
        readonly property real overshoot: 1.4
        readonly property real arriveShare: 0.5
        readonly property int faceEnter: 140
        readonly property int faceLeave: 90
        readonly property int stagger: 40
        readonly property int settle: 160
        readonly property real swipe: 64
        readonly property real fling: 900
    }

    readonly property QtObject extension: QtObject {
        readonly property int grow: 360
        readonly property int shrink: 240
        readonly property real handBack: 0.35
        readonly property real contentShare: 0.7
        readonly property int linger: 900
    }

    readonly property QtObject type: QtObject {
        readonly property int character: 60
        readonly property int untype: 30
        readonly property int quick: 22
        readonly property int quickUntype: 10
    }

    readonly property QtObject tip: QtObject {
        readonly property int pop: 150
        readonly property int resize: 140
        readonly property int follow: 140
        readonly property int grace: 40
        readonly property int character: 14
        readonly property int untype: 6
        readonly property int retype: 9
        readonly property int retypeUntype: 4
    }

    readonly property QtObject hover: QtObject {
        readonly property int openDelay: 150
        readonly property int closeDelay: 90
        readonly property int triangleGrace: 280
    }

    readonly property QtObject fold: QtObject {
        readonly property real threshold: 24
        readonly property int dotDelay: 90
    }

    readonly property QtObject reveal: QtObject {
        readonly property int dwell: 300
        readonly property int nudge: 700
        readonly property int linger: 200
        readonly property int stagger: 30
        readonly property int arrivalStagger: 45
        readonly property int tipDelay: 350
        readonly property int backdropEnter: 360
        readonly property int backdropLeave: 210
        readonly property real beadReach: 12
    }

    readonly property QtObject carry: QtObject {
        readonly property real pinch: 64
        readonly property real capture: 18
        readonly property real spread: 0.62
        readonly property real handle: 2.4
        readonly property real tide: 0.22
        readonly property real snapSpread: 0.32
        readonly property real stretchPerVelocity: 0.00008
        readonly property real stretchLimit: 0.18
        readonly property real restDistance: 0.5
        readonly property real restVelocity: 8
        readonly property real lift: 1.08
        readonly property real absorb: 0.42
        readonly property real iconAbsorb: 0.16
        readonly property real swell: 6
        readonly property int release: 260
    }

    readonly property QtObject settings: QtObject {
        readonly property int write: 250
        readonly property int dim: 200
        readonly property int dimOut: 200
        readonly property int pageSwap: 140
        readonly property int revealLeave: pageSwap
        readonly property int stagger: 40
        readonly property int waveRun: 700
        readonly property int slide: 200
        readonly property int cellCascade: 2
        readonly property int cellEnter: 90
        readonly property int cellLeave: Math.min(70, pageSwap)
        readonly property int outlineTrace: 520
        readonly property int outlineLeave: Math.min(120, pageSwap)
        readonly property int wipe: 260
        readonly property int wipeLeave: Math.min(120, pageSwap)
        readonly property int wheelPop: 320
    }

    readonly property QtObject desktop: QtObject {
        readonly property int settle: 140
    }

    readonly property QtObject dashboard: QtObject {
        readonly property int poll: 1500
        readonly property int trafficPoll: 1000
        readonly property int trafficSamples: 60
        readonly property int pingSamples: 10
        readonly property int weatherPoll: 900000
        readonly property int historySave: 30000
        readonly property real taskAt: 0.55
        readonly property int taskGrow: 640
        readonly property int taskShrink: 180
        readonly property int taskLag: 140
        readonly property real taskOvershoot: 1.1
        readonly property real taskArrive: 0.6
        readonly property int taskStagger: 14
        readonly property int taskStaggerRows: 16
        readonly property int taskMove: 220
        readonly property int taskTab: 260
        readonly property int menu: 160
        readonly property int menuOut: 110
        readonly property int dim: 200
        readonly property int dimOut: 200
        readonly property real reveal: 0.3
        readonly property int level: 600
    }

    readonly property QtObject burst: QtObject {
        readonly property int converge: 540
        readonly property real handShare: 0.4
        readonly property real settleShare: 0.16
        readonly property real convergeLag: 0.35
        readonly property real gulp: 0.3
        readonly property real gulpLimit: 0.4
        readonly property real recoil: 0.28
        readonly property real shrinkShare: 0.45
        readonly property real travelStart: 0.4
        readonly property real absorbShare: 0.25
        readonly property int spread: 900
        readonly property real impactShare: 0.1
        readonly property real inflate: 0.18
        readonly property real squash: 0.16
        readonly property real rootShare: 0.2
        readonly property real heightLead: 1.6
        readonly property real drag: 0.35
        readonly property real crestRise: 0.12
        readonly property real crestRun: 0.6
        readonly property int impact: 1000
        readonly property real moundPeak: 0.16
        readonly property real moundSink: 0.4
        readonly property real moundRise: 0.6
        readonly property real jetShare: 0.55
        readonly property real impactSquash: 0.5
        readonly property real splashSpan: 0.5
        readonly property real openShare: 0.14
        readonly property real flareStart: 0.65
        readonly property real flareRetract: 0.3
        readonly property int leaveHold: 60
        readonly property int leave: 380
        readonly property real leaveShrink: 0.55
        readonly property int release: 440
        readonly property real releaseEmerge: 0.2
        readonly property real releaseTravel: 0.4
        readonly property real releaseExtendLead: 0.104
        readonly property real releaseExtendSpeed: 0.7
        readonly property real releaseRebound: 1.6
        readonly property real stepRetract: 0.12
        readonly property real leaveFade: 0.2
        readonly property int split: 420
        readonly property real splitClose: 0.3
    }

    readonly property QtObject rising: QtObject {
        readonly property int interval: 240
        readonly property real speed: 38
        readonly property real lift: 34
        readonly property real grow: 0.3
        readonly property real life: 9
        readonly property real drain: 0.25
    }

    readonly property QtObject notifications: QtObject {
        readonly property int dim: 200
        readonly property int dimOut: 220
        readonly property int bud: 380
        readonly property int budOut: 140
        readonly property int stagger: 34
        readonly property int bubbleStagger: 90
        readonly property int rowEnter: 220
        readonly property int rowLeave: 110
        readonly property int iconEnter: 360
        readonly property real iconSpin: -200
        readonly property int typeCharacter: 12
        readonly property int settle: 180
        readonly property real sendShown: 0.6
    }

    readonly property QtObject search: QtObject {
        readonly property int dim: 200
        readonly property int dimOut: 220
        readonly property int tileEnter: 200
        readonly property real ripple: 0.32
        readonly property int settledStagger: 18
        readonly property int swap: 90
        readonly property int mutate: 220
        readonly property int bud: 340
        readonly property int budOut: 140
        readonly property int nameGrow: 360
        readonly property int nameShrink: 110
        readonly property real nameHeightLead: 2.5
    }

    readonly property QtObject budget: QtObject {
        readonly property real frame: 4
        readonly property real sampleShare: 0.95
        readonly property QtObject ready: QtObject {
            readonly property int glance: 250
            readonly property int focus: 700
            readonly property int takeover: 700
        }
    }

    readonly property QtObject lifecycle: QtObject {
        readonly property int stuck: 3000
    }

    readonly property QtObject frames: QtObject {
        readonly property int stepTimeout: 250
        readonly property real stepMinimum: 12
        readonly property int history: 120
        readonly property real memory: 1024 * 1024 * 1024
        readonly property int bytesPerPixel: 4
        readonly property real scale: 1
    }

    readonly property QtObject store: QtObject {
        readonly property int write: 400
    }

    readonly property QtObject supervision: QtObject {
        readonly property int base: 1000
        readonly property real factor: 2
        readonly property int cap: 60000
        readonly property int healthy: 30000
    }

    readonly property QtObject attention: QtObject {
        readonly property int peek: 5000
        readonly property int batch: 600
        readonly property int ownerProbe: 1000
    }

    readonly property QtObject gesture: QtObject {
        readonly property real slop: 6
        readonly property real velocityBlend: 0.4
    }

    readonly property QtObject liquid: QtObject {
        readonly property real substep: 1 / 240
        readonly property real frameCap: 0.05
        readonly property QtObject burst: QtObject {
            readonly property real response: 0.5466
            readonly property real damping: 0.537
            readonly property real expansion: 0.6366
        }
        readonly property QtObject crash: QtObject {
            readonly property real response: 0.5289
            readonly property real damping: 0.3788
            readonly property real expansion: 1
        }
        readonly property QtObject pill: QtObject {
            readonly property real response: 0.068
            readonly property real damping: 0.67
            readonly property real expansion: 1
        }
        readonly property QtObject circle: QtObject {
            readonly property real response: 0.2493
            readonly property real damping: 0.67
            readonly property real expansion: 1
        }
        readonly property QtObject gulp: QtObject {
            readonly property real response: 0.14
            readonly property real damping: 0.3
            readonly property real expansion: 1
        }
        readonly property QtObject follow: QtObject {
            readonly property real response: 0.12
            readonly property real damping: 0.65
            readonly property real expansion: 0
        }
        readonly property QtObject dock: QtObject {
            readonly property real response: 0.38
            readonly property real damping: 0.7
            readonly property real expansion: 0
        }
        readonly property QtObject droplet: QtObject {
            readonly property real response: 0.2
            readonly property real damping: 0.3
            readonly property real expansion: 0
        }
        readonly property QtObject neck: QtObject {
            readonly property real merge: 0.5
            readonly property real separate: 0.28
            readonly property real mergeKick: 3
            readonly property real separateKick: 5
        }
    }

    function holdAgain() {
        if (!isHeld)
            return
        isHeld = false
        isHeld = true
    }

    function pace(duration) {
        return isReduced ? 0 : duration
    }
}
