import '../models/models.dart';

const List<Journey> builtInJourneys = <Journey>[
  Journey(
    id: 'karma-yoga-7',
    title: 'Karma Yoga',
    description:
        'A 7-day path to selfless action, steadiness, and purposeful work.',
    days: 7,
    status: 'not_started',
    plan: <JourneyDay>[
      JourneyDay(
        day: 1,
        chapter: 2,
        verseNumber: 47,
        verseRef: '2.47',
        verseFocus:
            'Your role is in effort, not in owning the final result.',
        commentary:
            'Begin by separating what you can do from what you cannot control.',
        microPractice:
            'Before one task today, write: "My focus is sincere effort."',
        reflectionPrompt:
            'What changes when I measure my day by effort instead of outcome?',
      ),
      JourneyDay(
        day: 2,
        chapter: 2,
        verseNumber: 48,
        verseRef: '2.48',
        verseFocus:
            'Stay balanced in both success and failure; that balance is yoga.',
        commentary:
            'Results will move, but your center does not need to move with them.',
        microPractice:
            'Take three slow breaths before checking any important result.',
        reflectionPrompt:
            'Where did I stay steady today when outcomes were uncertain?',
      ),
      JourneyDay(
        day: 3,
        chapter: 3,
        verseNumber: 19,
        verseRef: '3.19',
        verseFocus:
            'Act without attachment and perform what should be done.',
        commentary:
            'Duty becomes lighter when it is done as service, not as ego proof.',
        microPractice:
            'Complete one pending duty quietly, without announcing it.',
        reflectionPrompt:
            'Which action today felt cleaner when I dropped self-importance?',
      ),
      JourneyDay(
        day: 4,
        chapter: 3,
        verseNumber: 30,
        verseRef: '3.30',
        verseFocus:
            'Offer your actions to the Divine and work without agitation.',
        commentary:
            'Inner offering reduces mental friction before and during work.',
        microPractice:
            'Before starting work, pause and dedicate the next hour to service.',
        reflectionPrompt:
            'How did my energy shift after consciously offering my action?',
      ),
      JourneyDay(
        day: 5,
        chapter: 3,
        verseNumber: 35,
        verseRef: '3.35',
        verseFocus:
            'Better to do your own dharma imperfectly than another path well.',
        commentary:
            'Comparison drains strength; alignment with your nature restores it.',
        microPractice:
            'List one responsibility that is truly yours, and do it first.',
        reflectionPrompt:
            'Where do I compare, and what is my own path asking of me instead?',
      ),
      JourneyDay(
        day: 6,
        chapter: 4,
        verseNumber: 18,
        verseRef: '4.18',
        verseFocus:
            'The wise find stillness in action and action within stillness.',
        commentary:
            'Outer movement can coexist with inner quiet attention.',
        microPractice:
            'For ten minutes, do a routine task with full single-pointed focus.',
        reflectionPrompt:
            'What happened when I worked from quiet attention rather than hurry?',
      ),
      JourneyDay(
        day: 7,
        chapter: 18,
        verseNumber: 46,
        verseRef: '18.46',
        verseFocus:
            'By doing your own work as worship, you move toward fulfillment.',
        commentary:
            'Purpose deepens when ordinary duty is treated as sacred practice.',
        microPractice:
            'Choose one daily chore and perform it as an offering.',
        reflectionPrompt:
            'How does my work change when I treat it as worship?',
      ),
    ],
  ),
  Journey(
    id: 'anxiety-steadiness-5',
    title: 'Anxiety & steadiness',
    description:
        'A 5-day grounding path for emotional regulation and inner balance.',
    days: 5,
    status: 'not_started',
    plan: <JourneyDay>[
      JourneyDay(
        day: 1,
        chapter: 2,
        verseNumber: 14,
        verseRef: '2.14',
        verseFocus:
            'Sensations and emotional waves arise and pass; endure them calmly.',
        commentary:
            'Anxious states feel permanent, but the Gita reminds they are moving.',
        microPractice:
            'Name your feeling and add: "This is present, and this will pass."',
        reflectionPrompt:
            'Which difficult feeling softened when I stopped resisting it?',
      ),
      JourneyDay(
        day: 2,
        chapter: 2,
        verseNumber: 48,
        verseRef: '2.48',
        verseFocus:
            'Stay even-minded in gain and loss, success and failure.',
        commentary:
            'Calm is built by returning to balance each time the mind swings.',
        microPractice:
            'When triggered, feel both feet on the ground for 30 seconds.',
        reflectionPrompt:
            'Where did I regain balance after a mental swing today?',
      ),
      JourneyDay(
        day: 3,
        chapter: 6,
        verseNumber: 26,
        verseRef: '6.26',
        verseFocus:
            'Whenever the mind wanders, gently bring it back again.',
        commentary:
            'Progress is not zero wandering; progress is gentle returning.',
        microPractice:
            'Set a 3-minute timer: on each distraction, return to the breath.',
        reflectionPrompt:
            'How did I speak to myself while bringing my mind back?',
      ),
      JourneyDay(
        day: 4,
        chapter: 12,
        verseNumber: 15,
        verseRef: '12.15',
        verseFocus:
            'The steady one neither disturbs others nor is shaken by them.',
        commentary:
            'Steadiness includes both emotional boundaries and kindness.',
        microPractice:
            'Choose one response today that is calm, brief, and non-reactive.',
        reflectionPrompt:
            'What helped me stay calm without suppressing what I felt?',
      ),
      JourneyDay(
        day: 5,
        chapter: 18,
        verseNumber: 66,
        verseRef: '18.66',
        verseFocus:
            'Release fear into trust; surrender the burden you cannot carry.',
        commentary:
            'Surrender here means wise letting-go, not passivity.',
        microPractice:
            'Write one fear on paper and end with: "I release this for now."',
        reflectionPrompt:
            'What burden felt lighter when I practiced trust today?',
      ),
    ],
  ),
  Journey(
    id: 'daily-dhyana-21',
    title: 'Daily Dhyana',
    description:
        'A 21-day meditation rhythm for posture, breath, focus, and inner quiet.',
    days: 21,
    status: 'not_started',
    plan: <JourneyDay>[
      JourneyDay(
        day: 1,
        chapter: 6,
        verseNumber: 10,
        verseRef: '6.10',
        verseFocus:
            'Practice regularly in a quiet place with disciplined intention.',
        commentary:
            'Meditation stabilizes through rhythm more than intensity.',
        microPractice:
            'Pick one fixed time today for a 5-minute silent sit.',
        reflectionPrompt:
            'What time and place felt most supportive for stillness?',
      ),
      JourneyDay(
        day: 2,
        chapter: 6,
        verseNumber: 11,
        verseRef: '6.11',
        verseFocus: 'Prepare a clean and steady seat for practice.',
        commentary:
            'A consistent physical setup signals your mind to settle sooner.',
        microPractice:
            'Create a simple meditation corner with one dedicated seat.',
        reflectionPrompt:
            'How did preparing the space influence my mental state?',
      ),
      JourneyDay(
        day: 3,
        chapter: 6,
        verseNumber: 12,
        verseRef: '6.12',
        verseFocus: 'Sit there and gently make the mind one-pointed.',
        commentary:
            'Attention becomes stronger when guided to a single anchor.',
        microPractice:
            'Use breath counting from 1 to 10, then restart.',
        reflectionPrompt:
            'What anchor helped me hold attention most naturally?',
      ),
      JourneyDay(
        day: 4,
        chapter: 6,
        verseNumber: 13,
        verseRef: '6.13',
        verseFocus:
            'Keep body, head, and neck aligned in steady stillness.',
        commentary:
            'Posture is not rigid perfection; it is alert ease.',
        microPractice:
            'For 5 minutes, keep the spine tall and shoulders relaxed.',
        reflectionPrompt:
            'What changed in my mind when my posture was balanced?',
      ),
      JourneyDay(
        day: 5,
        chapter: 6,
        verseNumber: 14,
        verseRef: '6.14',
        verseFocus:
            'Practice with calm courage and a heart free from fear.',
        commentary:
            'Gentle fearlessness grows when you stay present to discomfort.',
        microPractice:
            'During practice, soften jaw and belly whenever tension appears.',
        reflectionPrompt:
            'Where did I notice fear, and how did I stay with it?',
      ),
      JourneyDay(
        day: 6,
        chapter: 6,
        verseNumber: 15,
        verseRef: '6.15',
        verseFocus:
            'A steady, disciplined mind leads toward deep peace.',
        commentary:
            'Inner peace is usually cumulative, not instant.',
        microPractice:
            'Extend your sit by one extra minute beyond comfort.',
        reflectionPrompt:
            'What kind of peace appeared, even briefly, in today\'s sit?',
      ),
      JourneyDay(
        day: 7,
        chapter: 6,
        verseNumber: 16,
        verseRef: '6.16',
        verseFocus:
            'Meditation does not flourish in extremes of lifestyle.',
        commentary:
            'Overdoing and underdoing both destabilize the mind.',
        microPractice:
            'Choose one small balance correction in food, sleep, or work.',
        reflectionPrompt:
            'Which extreme pattern most affects my steadiness?',
      ),
      JourneyDay(
        day: 8,
        chapter: 6,
        verseNumber: 17,
        verseRef: '6.17',
        verseFocus:
            'Balance in living supports the end of suffering.',
        commentary:
            'A moderate daily rhythm supports clear awareness.',
        microPractice:
            'Take a mindful 7-minute walk after one meal today.',
        reflectionPrompt:
            'Where did moderation make my day feel clearer?',
      ),
      JourneyDay(
        day: 9,
        chapter: 6,
        verseNumber: 18,
        verseRef: '6.18',
        verseFocus:
            'When mind rests in the Self, it becomes deeply steady.',
        commentary:
            'Stillness grows when attention turns inward, not outward.',
        microPractice:
            'After exhaling, rest in one silent pause before the next breath.',
        reflectionPrompt:
            'How did inward attention feel different from outward attention?',
      ),
      JourneyDay(
        day: 10,
        chapter: 6,
        verseNumber: 19,
        verseRef: '6.19',
        verseFocus:
            'A quiet mind is like a lamp in a windless space.',
        commentary:
            'Subtle calm is often a sign of progress, even if brief.',
        microPractice:
            'Reduce one digital distraction before meditation today.',
        reflectionPrompt:
            'What helped protect the "windless" quality of my attention?',
      ),
      JourneyDay(
        day: 11,
        chapter: 6,
        verseNumber: 20,
        verseRef: '6.20',
        verseFocus:
            'Through practice, the mind settles into inner stillness.',
        commentary:
            'When thoughts slow down, observe without forcing silence.',
        microPractice:
            'Sit for 6 minutes and simply notice thoughts passing by.',
        reflectionPrompt:
            'What happened when I observed thoughts without chasing them?',
      ),
      JourneyDay(
        day: 12,
        chapter: 6,
        verseNumber: 21,
        verseRef: '6.21',
        verseFocus:
            'Inner joy, beyond senses, can be touched in deep quiet.',
        commentary:
            'Meditation refines fulfillment from external to internal.',
        microPractice:
            'Close practice by noticing one subtle feeling of inner ease.',
        reflectionPrompt:
            'What kind of joy appeared when I became more still?',
      ),
      JourneyDay(
        day: 13,
        chapter: 6,
        verseNumber: 22,
        verseRef: '6.22',
        verseFocus:
            'Established in this state, one is not shaken by sorrow.',
        commentary:
            'Stability does not remove life\'s pain, but changes your center.',
        microPractice:
            'Recall one recent stress and breathe through it for 2 minutes.',
        reflectionPrompt:
            'How is my response to stress changing through practice?',
      ),
      JourneyDay(
        day: 14,
        chapter: 6,
        verseNumber: 23,
        verseRef: '6.23',
        verseFocus:
            'Resolve firmly to unite with this freedom from sorrow.',
        commentary:
            'Consistency comes from clear resolve, not mood.',
        microPractice:
            'Write a one-line meditation commitment for the next 7 days.',
        reflectionPrompt:
            'What helps me continue when I do not feel like practicing?',
      ),
      JourneyDay(
        day: 15,
        chapter: 6,
        verseNumber: 25,
        verseRef: '6.25',
        verseFocus:
            'With patience and intellect, gradually quiet the mind.',
        commentary:
            'The Gita emphasizes gradual settling, never self-violence.',
        microPractice:
            'When restless, lengthen each exhale slightly for 10 breaths.',
        reflectionPrompt:
            'How did patience change the quality of my meditation?',
      ),
      JourneyDay(
        day: 16,
        chapter: 6,
        verseNumber: 26,
        verseRef: '6.26',
        verseFocus:
            'Every wandering is an opportunity to return to center.',
        commentary:
            'Gentle repetition rewires attention over time.',
        microPractice:
            'Count each return during practice; honor every return as progress.',
        reflectionPrompt:
            'What did I learn from how often and how gently I returned?',
      ),
      JourneyDay(
        day: 17,
        chapter: 6,
        verseNumber: 27,
        verseRef: '6.27',
        verseFocus:
            'A calm mind tastes the highest peace and clarity.',
        commentary:
            'Peace deepens when agitation is met with compassionate awareness.',
        microPractice:
            'After meditation, sit 1 extra minute in silence before moving.',
        reflectionPrompt:
            'What signs of calm are becoming more available to me?',
      ),
      JourneyDay(
        day: 18,
        chapter: 6,
        verseNumber: 28,
        verseRef: '6.28',
        verseFocus:
            'Regular practice gradually purifies and uplifts the mind.',
        commentary:
            'Small daily sessions are more transformative than occasional long ones.',
        microPractice:
            'Keep your sit short but non-negotiable today.',
        reflectionPrompt:
            'How is regularity affecting my inner tone through the day?',
      ),
      JourneyDay(
        day: 19,
        chapter: 6,
        verseNumber: 35,
        verseRef: '6.35',
        verseFocus:
            'Mind is trained by practice and by letting go of clinging.',
        commentary:
            'Discipline and detachment work together, not separately.',
        microPractice:
            'Notice one mental grip and whisper: "Not now, I return."',
        reflectionPrompt:
            'What attachment most pulls my mind, and how can I soften it?',
      ),
      JourneyDay(
        day: 20,
        chapter: 5,
        verseNumber: 27,
        verseRef: '5.27',
        verseFocus:
            'Gather senses inward and regulate awareness of breath.',
        commentary:
            'Breath awareness can be a direct doorway to steadiness.',
        microPractice:
            'Practice 4 minutes of smooth nasal breathing with soft attention.',
        reflectionPrompt:
            'What did breath regulation change in my body and mind?',
      ),
      JourneyDay(
        day: 21,
        chapter: 12,
        verseNumber: 8,
        verseRef: '12.8',
        verseFocus:
            'Rest mind and heart in the Divine with steady devotion.',
        commentary:
            'Meditation matures into loving remembrance throughout the day.',
        microPractice:
            'Close with one minute of gratitude and a silent dedication.',
        reflectionPrompt:
            'How will I carry this 21-day rhythm into daily life now?',
      ),
    ],
  ),
];
