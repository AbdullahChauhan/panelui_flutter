# Component parity

23 of PanelUI's 141 components are ported. The list and the
one-line summaries come from PanelUI's own documentation metadata; the
Flutter column names the widget or function that ports each one.

To port one, see [PORTING.md](PORTING.md).

## Actions (2/12)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| Button | `PanelButton` | Pressable action with variants, sizes, loading state and icon slots. |
| ButtonGroup | `PanelButtonGroup` | Several buttons drawn as one control — a segmented run, a split action, a toolbar. |
| Chip | Not yet | Interactive pill — a filter, a tag, or a removable token. |
| ContextMenu | Not yet | Actions for a piece of content, opened by holding it. |
| Fab | Not yet | The floating action button — one action pinned over the content, with an optional dial of others behind it. |
| Menu | Not yet | The list of things you can do to something. |
| ProgressButton | Not yet | Press and hold to confirm, with the wait drawn on the button. |
| SelectionMode | Not yet | Pick several things at once, on a screen or in a sheet. |
| SlideButton | Not yet | Drag across to confirm, with the distance drawn on the button. |
| StackCard | Not yet | A pile of cards, taken one at a time by throwing the top one off. |
| Swipe | Not yet | A row that slides aside to reveal the things you can do to it. |
| ToggleButton | Not yet | A button that stays down, on its own or in a group. |

## Forms (9/27)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| Calendar | Not yet | A month of days, for picking one, several, or a range. |
| Checkbox | `PanelCheckbox` | Animated checkbox, as a row or a selectable card. |
| ColorPicker | Not yet | A colour chosen by dragging — a saturation square or a wheel, a hue scale, and opacity. |
| Combobox | Not yet | A text field that filters a list of options as you type. |
| DatePicker | Not yet | A calendar behind a button. |
| DateTimePicker | Not yet | A day and a time of day, picked in one panel. |
| Field | `PanelField`, `PanelFieldSet` | Layout and validation-state kit a form control composes into. |
| FileUpload | Not yet | Pick files and photos, check them, and run their uploads. |
| Form | Not yet | Form state — values, validation and submission — with no form library underneath. |
| Input | `PanelInput` | Text field with label, description and error message. |
| InputGroup | Not yet | Input with leading and trailing decorators. |
| Label | `PanelLabel` | Form field label with required, invalid and disabled states. |
| MarkdownEditor | Not yet | A field for writing markdown, with a formatting toolbar and a rendered preview. |
| NumberInput | `PanelNumberInput` | Numeric field stepped by buttons or typed by hand. |
| OtpInput | `PanelOtpInput` | One-time-code field drawn as a row of separate cells. |
| Questionnaire | Not yet | One question at a time, with progress, validation and a way back. |
| RadioGroup | Not yet | Single-select list of options. |
| Rating | Not yet | A row of stars to read or set a score. |
| SearchBar | Not yet | Search field with a clear button, a Cancel button and a panel of results. |
| Select | Not yet | Picker shown in a bottom sheet, expanded in place, or floating over the page. |
| Signature | Not yet | Sign with a finger, and get the result back out as SVG or PNG. |
| Slider | Not yet | Pick a value, or a span, by dragging a thumb along a track. |
| Switch | `PanelSwitch` | Animated on/off toggle. |
| TagInput | Not yet | A field whose value is a list of tokens rather than a string. |
| Textarea | `PanelTextarea` | Text field that runs to several lines, sized in rows. |
| ThemeSelector | `PanelThemeSelector` | Light, dark or the device's setting, drawn as three miniature screens. |
| TimePicker | Not yet | A time of day, as a wheel, a clock or a swipeable scale. |

## Feedback (6/10)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| Alert | `PanelAlert` | Status message with a built-in icon. |
| AnimatedBadge | Not yet | Status pill whose icon and label roll over when the status changes. |
| Badge | `PanelBadge` | Compact status label, dot, or notification count. |
| EmptyState | `PanelEmptyState` | Placeholder for a list or screen with no content. |
| Loader | Not yet | Nine loading animations behind one variant prop. |
| Marker | Not yet | Inline note between conversation turns. |
| Meter | `PanelMeter` | A measurement on a fixed scale, coloured by where it falls. |
| Progress | Not yet | Determinate and indeterminate progress bar. |
| Skeleton | `PanelSkeleton` | Shimmer placeholder for loading content. |
| Spinner | `PanelSpinner` | Indeterminate loading indicator. |

## Overlays (0/7)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| BottomSheet | Not yet | Draggable sheet anchored to the bottom of the screen. |
| Dialog | Not yet | Modal dialog with a backdrop and footer actions. |
| Drawer | Not yet | A panel that comes in from an edge of the screen and covers the app until dismissed. |
| Feedback | Not yet | Dialog whose body is a well to write in, with the actions in the band around it. |
| Popover | Not yet | Panel anchored to the element that opened it. |
| Toast | Not yet | Transient notification queue with swipe to dismiss. |
| Tooltip | Not yet | A small label that names the control under your finger. |

## Navigation (0/9)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| Breadcrumb | Not yet | The trail of links back up the hierarchy to the current page. |
| Pagination | Not yet | Paged navigation over a long result set. |
| SectionProgress | Not yet | Floating pill with a scroll ring and the section being read. |
| SectionRail | Not yet | Floating section navigator for a long screen. |
| Sortable | Not yet | A list whose rows can be dragged into a different order. |
| Steps | Not yet | Stepper for multi-step flows. |
| Tabs | Not yet | Segmented navigation with an animated indicator. |
| Tour | Not yet | A walkthrough that introduces a screen one control at a time. |
| Tree | Not yet | A hierarchy you can open a level at a time. |

## Layout (6/18)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| Accordion | Not yet | Collapsible sections with single or multiple selection. |
| Card | `PanelCard` | Content surface with header, body and footer. |
| Carousel | Not yet | A run of slides, one at a time, dragged with a finger. |
| Collapsible | Not yet | One section of content, shown and hidden by its own header. |
| Direction | `Directionality (built into Flutter)` | Reading direction for everything below it. |
| Frame | Not yet | Widget shell — a card of rows sitting in a titled tray. |
| GridItem | Not yet | Bento tiles, and the grid that places them. |
| Item | Not yet | Row of media, text and actions for lists and settings. |
| PageHeader | Not yet | Cover, face and actions at the top of a profile. |
| ScrollBlur | Not yet | Blurs the edges of a scroll container. |
| ScrollCanvas | Not yet | Image frame whose contents move as you scroll. |
| ScrollFade | `PanelScrollFade` | Fades the edges of a scroll container. |
| ScrollHeader | Not yet | A screen title that hands over to a compact bar as the page scrolls. |
| Separator | `PanelSeparator` | Horizontal or vertical rule between content, optionally labelled. |
| Splitter | Not yet | Panes that share a container, with a seam between them you can drag. |
| SplitView | Not yet | Two resizable stacked panes that settle on one of a few named heights. |
| Surface | `PanelSurface` | Elevated container with a variant ladder. |
| Typography | `PanelText.h1`, `PanelBlockquote`, `PanelCode`, `PanelList` | Semantic text presets. |

## Data display (0/8)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| Countdown | Not yet | The time left until a moment, ticking down to it. |
| Flow | Not yet | Pan-and-zoom canvas of draggable nodes joined by animated edges. |
| Kpi | Not yet | One number, what it is doing, and the shape it made getting there. |
| Leaderboard | Not yet | Entries ranked by a value, with the top three on a podium. |
| Map | Not yet | Vector map whose basemap is drawn from your theme tokens. |
| Planner | Not yet | A month of days, each carrying what falls on it. |
| Table | Not yet | Rows and columns that stay lined up, with sortable headers. |
| Timeline | Not yet | A sequence of events, vertical or swiped sideways. |

## Media (0/15)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| Attachment | Not yet | File row with upload states, built on Item. |
| Avatar | Not yet | User image with an initials fallback, a badge overlay, and a stack for a group of them. |
| AvatarCropper | Not yet | Frame a photo under a circle, and get that circle back as an image. |
| Camera | Not yet | A full-screen camera you assemble from parts. |
| CircularText | Not yet | Text set around a circle, turning. |
| Compare | Not yet | Two versions of one picture, with a seam you drag across it. |
| FlipCard | Not yet | Two faces of one card, and a turn between them. |
| Marquee | Not yet | Content that travels across its container on a loop. |
| Message | Not yet | Chat turn with avatar, bubble, header and footer. |
| MessageScroller | Not yet | Scroll behaviour a chat transcript needs. |
| Post | Not yet | A social card — author, body, media and the counts underneath, with the votes animated. |
| QRCode | Not yet | A string a camera can read — framed, titled, or folded away behind a button. |
| ScrollText | Not yet | Text that resolves word by word as you scroll. |
| Support | Not yet | The screen a person arrives on when they need help. |
| TextAnimation | Not yet | Five ways a piece of text or a number arrives. |

## Other (0/2)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| ImageViewer | Not yet | An image that opens out of the page over a blur, to zoom into and swipe through. |
| Sketch | Not yet | Draw with a pen, shapes and an eraser, in a sheet or a whole screen. |

## Charts (0/21)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| AreaChart | Not yet | Filled bands over time, stacked or overlaid. |
| BarChart | Not yet | Categories compared by length, grouped or stacked. |
| BubbleChart | Not yet | Named circles on two axes, with a third quantity on their area. |
| BumpChart | Not yet | How a set of things ranked against each other over time. |
| CandlestickChart | Not yet | Open, high, low and close for a period, drawn as one mark. |
| FunnelChart | Not yet | Where a population drained away, one step at a time. |
| HeatmapChart | Not yet | Contribution grid with a themed colour ramp and a readout. |
| HexChart | Not yet | A whole broken into parts, counted out in cells. |
| LineChart | Not yet | Animated time series, drawn on the UI thread. |
| LiveLineChart | Not yet | A reading that keeps arriving, against a window that keeps moving. |
| MirrorAreaChart | Not yet | Two readings of one timeline, one above a baseline and one below it. |
| PieChart | Not yet | One whole, divided between its parts. |
| Plot | Not yet | A chart you assemble out of its marks. |
| PolarAreaChart | Not yet | Several readings on one scale, compared as wedges. |
| PyramidChart | Not yet | Two series mirrored about a centre, on one shared scale. |
| RadarChart | Not yet | Several measures of one thing, drawn as one shape. |
| RingChart | Not yet | Concentric arcs, each measured against its own target. |
| SankeyChart | Not yet | Where a quantity came from and where it ended up. |
| ScatterChart | Not yet | Two quantities against each other, to show how they relate. |
| TreemapChart | Not yet | A total, cut into the parts it is made of, sized by area. |
| WaterfallChart | Not yet | How a run of changes carried one total to another. |

## AI components (0/12)

| PanelUI | Flutter | What it is |
| --- | --- | --- |
| AIInput | Not yet | A prompt composer: a field that grows to five lines, a row of controls, and the sheet they open. |
| CodeBlock | Not yet | A fenced snippet, syntax-coloured and scrolled sideways. |
| ImageGeneration | Not yet | The place an image will be, while it is being made. |
| Panelside | Not yet | Navigation panel that moves the app aside instead of covering it. |
| Plan | Not yet | What an agent intends to do, before it does it. |
| Reasoning | Not yet | The model's working, shown while it happens and folded away after. |
| Response | Not yet | A model's answer, rendered as markdown while it is still arriving. |
| Shimmer | Not yet | Animated highlight sweeping across content. |
| Soundwave | Not yet | What a voice looks like while an app listens. |
| Sources | Not yet | Where an answer came from, folded under a count. |
| Task | Not yet | One step an agent took, and what it did while it was there. |
| ThinkingOrb | Not yet | Dotted orb saying which kind of busy an agent is. |
