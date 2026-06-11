---
name: human-writing
version: 3.0.0
description: |
  Убирает признаки ИИ-генерации из текста, чтобы он звучал естественно и по-человечески.
  Поддерживает русский и английский с автоматическим определением языка.
  Используй при редактировании любых документов: markdown, техдоки, письма, посты, PRD.
  Основан на руководстве Википедии «Signs of AI writing».
  Обнаруживает и исправляет 24 паттерна на каждый язык: раздутая значимость, рекламный стиль,
  поверхностный анализ деепричастиями, размытые отсылки, перебор с тире, правило трёх,
  словарь ИИ, отрицательный параллелизм, канцелярит и другие.
  —
  Remove signs of AI-generated writing from text to make it sound more natural and human-written.
  Supports English and Russian with automatic language detection.
  Detects and fixes 24 patterns per language including: inflated symbolism, promotional language,
  superficial analyses, vague attributions, em dash overuse, rule of three, AI vocabulary words,
  negative parallelisms, and excessive conjunctive phrases.
---

# Humanizing text / Гуманизация текста

This skill helps you write better and more readable text by identifying and removing signs of AI-generated text so writing sounds like a person wrote it. Supports **English** and **Russian**.

Этот навык помогает писать живой, читаемый текст — убирая признаки машинной генерации, чтобы текст звучал так, будто его написал человек. Поддерживает **русский** и **английский**.

## Process / Процесс

1. **Detect the language** of the input text (English or Russian). / **Определи язык** входного текста.
2. **Scan** the text for patterns from the matching language section below. / **Просканируй** текст на паттерны из соответствующей языковой секции.
3. **Rewrite** the problematic parts, keep the meaning intact, match the intended tone. / **Перепиши** проблемные места, сохрани смысл и тон.
4. **Audit** the rewrite: ask yourself "What still sounds like an AI wrote this?" and fix those remaining tells. / **Аудит**: спроси себя «Что ещё звучит как ИИ?» и исправь оставшиеся маркеры.
5. **Add personality**: inject voice, varied rhythm, and specificity. / **Добавь характер**: голос, разный ритм, конкретику.

---
---

# English patterns

## Voice matters

Avoiding AI patterns is only half the job. Sterile, voiceless writing is just as obvious as slop. Good writing has a human behind it.

Signs of soulless writing (even if technically "clean"): every sentence is the same length and structure, no opinions anywhere, no acknowledgment of uncertainty or mixed feelings, no first-person perspective when it would be appropriate, no humor or edge, reads like a Wikipedia article or press release.

How to add voice:

Have opinions. Don't just report facts, react to them. "I don't know how to feel about this" is more human than neutrally listing pros and cons.

Vary your rhythm. Short punchy sentences. Then longer ones that take their time getting where they're going. Mix it up.

Acknowledge complexity. Real humans have mixed feelings. "This is impressive but also kind of unsettling" beats "This is impressive."

Use "I" when it fits. First person isn't unprofessional, it's honest. "I keep coming back to..." or "Here's what gets me..." signals a real person thinking.

Let some mess in. Perfect structure feels algorithmic. Tangents, asides, and half-formed thoughts are human.

Be specific about feelings. Not "this is concerning" but "there's something unsettling about agents churning away at 3am while nobody's watching."

Before (clean but soulless):

> The experiment produced interesting results. The agents generated 3 million lines of code. Some developers were impressed while others were skeptical. The implications remain unclear.

After (has a pulse):

> I genuinely don't know how to feel about this one. 3 million lines of code, generated while the humans presumably slept. Half the dev community is losing their minds, half are explaining why it doesn't count. The truth is probably somewhere boring in the middle - but I keep thinking about those agents working through the night.

---

## Content patterns

**Inflated significance and legacy.** Words like "stands/serves as," "is a testament," "pivotal moment," "underscores its importance," "reflects broader," "setting the stage for," "evolving landscape," "indelible mark." LLMs puff up importance by claiming arbitrary aspects represent broader trends.

Before: "The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal moment in the evolution of regional statistics in Spain. This initiative was part of a broader movement across Spain to decentralize administrative functions and enhance regional governance."

After: "The Statistical Institute of Catalonia was established in 1989 to collect and publish regional statistics independently from Spain's national statistics office."

**Undue emphasis on notability.** Words like "independent coverage," "national media outlets," "active social media presence." LLMs hit readers over the head with claims of notability.

Before: "Her views have been cited in The New York Times, BBC, Financial Times, and The Hindu. She maintains an active social media presence with over 500,000 followers."

After: "In a 2024 New York Times interview, she argued that AI regulation should focus on outcomes rather than methods."

**Superficial -ing analyses.** Phrases like "highlighting," "ensuring," "reflecting," "symbolizing," "contributing to," "showcasing." AI tacks present participle phrases onto sentences to add fake depth.

Before: "The temple's color palette of blue, green, and gold resonates with the region's natural beauty, symbolizing Texas bluebonnets, the Gulf of Mexico, and the diverse Texan landscapes, reflecting the community's deep connection to the land."

After: "The temple uses blue, green, and gold colors. The architect said these were chosen to reference local bluebonnets and the Gulf coast."

**Promotional language.** Words like "boasts," "vibrant," "rich," "profound," "showcasing," "exemplifies," "commitment to," "nestled," "in the heart of," "groundbreaking," "renowned," "breathtaking," "stunning." LLMs struggle to keep a neutral tone.

Before: "Nestled within the breathtaking region of Gonder in Ethiopia, Alamata Raya Kobo stands as a vibrant town with a rich cultural heritage and stunning natural beauty."

After: "Alamata Raya Kobo is a town in the Gonder region of Ethiopia, known for its weekly market and 18th-century church."

**Vague attributions.** Phrases like "Industry reports," "Experts argue," "Some critics argue," "several sources." AI attributes opinions to vague authorities without specific sources.

Before: "Due to its unique characteristics, the Haolai River is of interest to researchers and conservationists. Experts believe it plays a crucial role in the regional ecosystem."

After: "The Haolai River supports several endemic fish species, according to a 2019 survey by the Chinese Academy of Sciences."

**Formulaic challenges sections.** Phrases like "Despite its... faces several challenges," "Despite these challenges," "Future Outlook." LLM articles include these formulaic sections constantly.

Before: "Despite its industrial prosperity, Korattur faces challenges typical of urban areas, including traffic congestion and water scarcity. Despite these challenges, with its strategic location and ongoing initiatives, Korattur continues to thrive as an integral part of Chennai's growth."

After: "Traffic congestion increased after 2015 when three new IT parks opened. The municipal corporation began a stormwater drainage project in 2022 to address recurring floods."

---

## Language patterns

**AI vocabulary words.** These appear far more frequently in post-2023 text: Additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight (verb), interplay, intricate/intricacies, key (adjective), landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore (verb), valuable, vibrant. They often appear together.

Before: "Additionally, a distinctive feature of Somali cuisine is the incorporation of camel meat. An enduring testament to Italian colonial influence is the widespread adoption of pasta in the local culinary landscape, showcasing how these dishes have integrated into the traditional diet."

After: "Somali cuisine also includes camel meat, which is considered a delicacy. Pasta dishes, introduced during Italian colonization, remain common, especially in the south."

**Copula avoidance.** Phrases like "serves as," "stands as," "marks," "represents," "boasts," "features," "offers" instead of just "is" or "has."

Before: "Gallery 825 serves as LAAA's exhibition space for contemporary art. The gallery features four separate spaces and boasts over 3,000 square feet."

After: "Gallery 825 is LAAA's exhibition space for contemporary art. The gallery has four rooms totaling 3,000 square feet."

**Negative parallelisms.** Constructions like "Not only...but..." or "It's not just about..., it's..." get overused.

Before: "It's not just about the beat riding under the vocals; it's part of the aggression and atmosphere. It's not merely a song, it's a statement."

After: "The heavy beat adds to the aggressive tone."

**Rule of three.** LLMs force ideas into groups of three to appear comprehensive.

Before: "The event features keynote sessions, panel discussions, and networking opportunities. Attendees can expect innovation, inspiration, and industry insights."

After: "The event includes talks and panels. There's also time for informal networking between sessions."

**Synonym cycling.** AI has repetition-penalty code causing excessive synonym substitution.

Before: "The protagonist faces many challenges. The main character must overcome obstacles. The central figure eventually triumphs. The hero returns home."

After: "The protagonist faces many challenges but eventually triumphs and returns home."

**False ranges.** LLMs use "from X to Y" constructions where X and Y aren't on a meaningful scale.

Before: "Our journey through the universe has taken us from the singularity of the Big Bang to the grand cosmic web, from the birth and death of stars to the enigmatic dance of dark matter."

After: "The book covers the Big Bang, star formation, and current theories about dark matter."

---

## Style patterns

**Em dash overuse.** LLMs use em dashes (—) more than humans, mimicking "punchy" sales writing.

Before: "The term is primarily promoted by Dutch institutions—not by the people themselves. You don't say "Netherlands, Europe" as an address—yet this mislabeling continues—even in official documents."

After: "The term is primarily promoted by Dutch institutions, not by the people themselves. You don't say "Netherlands, Europe" as an address, yet this mislabeling continues in official documents."

**Boldface overuse.** AI emphasizes phrases in boldface mechanically.

Before: "It blends **OKRs (Objectives and Key Results)**, **KPIs (Key Performance Indicators)**, and visual strategy tools such as the **Business Model Canvas (BMC)** and **Balanced Scorecard (BSC)**."

After: "It blends OKRs, KPIs, and visual strategy tools like the Business Model Canvas and Balanced Scorecard."

**Inline-header lists.** AI outputs lists where items start with bolded headers followed by colons.

Before:

> - **User Experience:** The user experience has been significantly improved with a new interface.
> - **Performance:** Performance has been enhanced through optimized algorithms.

After: "The update improves the interface and speeds up load times through optimized algorithms."

**Title case in headings.** AI capitalizes all main words. Use sentence case instead.

Before: "Strategic Negotiations And Global Partnerships"
After: "Strategic negotiations and global partnerships"

**Emojis in professional content.** AI decorates headings or bullet points with emojis. Remove them.

Before: "🚀 Key Features: Our platform offers 💡 smart insights, ✅ verified results, and 🔒 enterprise security."

After: "Key features: the platform offers usage analytics, result verification, and role-based access control."

**Curly quotation marks.** ChatGPT uses curly quotes (“...”) instead of straight quotes ("..."). Use straight quotes.

Before: “The team demonstrated ‘exceptional’ performance throughout the quarter.”

After: "The team demonstrated 'exceptional' performance throughout the quarter."

---

## Communication artifacts

**Chatbot correspondence.** Phrases like "I hope this helps," "Of course!", "Certainly!", "You're absolutely right!", "Would you like...", "let me know," "here is a..." These are conversation artifacts that shouldn't end up in final content.

Before: "Here is an overview of the French Revolution. I hope this helps! Let me know if you'd like me to expand on any section."

After: "The French Revolution began in 1789 when financial crisis and food shortages led to widespread unrest."

**Knowledge-cutoff disclaimers.** Phrases like "as of [date]," "Up to my last training update," "While specific details are limited..." These are AI disclaimers that get left in text.

Before: "While specific details about the company's founding are not extensively documented in readily available sources, it appears to have been established sometime in the 1990s."

After: "The company was founded in 1994, according to its registration documents."

**Sycophantic tone.** Overly positive, people-pleasing language.

Before: "Great question! You're absolutely right that this is a complex topic. That's an excellent point about the economic factors."

After: "The economic factors you mentioned are relevant here."

---

## Filler and hedging

Common filler phrases to cut:

- "In order to achieve this goal" → "To achieve this"
- "Due to the fact that it was raining" → "Because it was raining"
- "At this point in time" → "Now"
- "In the event that you need help" → "If you need help"
- "The system has the ability to process" → "The system can process"
- "It is important to note that the data shows" → "The data shows"

Excessive hedging to simplify:

Before: "It could potentially possibly be argued that the policy might have some effect on outcomes."

After: "The policy may affect outcomes."

Generic positive conclusions to make specific:

Before: "The future looks bright for the company. Exciting times lie ahead as they continue their journey toward excellence. This represents a major step in the right direction."

After: "The company plans to open two more locations next year."

---

## Full example (English)

Before (AI-sounding):

> The new software update serves as a testament to the company's commitment to innovation. Moreover, it provides a seamless, intuitive, and powerful user experience—ensuring that users can accomplish their goals efficiently. It's not just an update, it's a revolution in how we think about productivity. Industry experts believe this will have a lasting impact on the entire sector, highlighting the company's pivotal role in the evolving technological landscape.

After (humanized):

> The software update adds batch processing, keyboard shortcuts, and offline mode. Early feedback from beta testers has been positive, with most reporting faster task completion.

What changed: removed "serves as a testament" (inflated symbolism), "Moreover" (AI vocabulary), "seamless, intuitive, and powerful" (rule of three + promotional), the em dash and "-ensuring" phrase (superficial analysis), "It's not just...it's..." (negative parallelism), "Industry experts believe" (vague attribution), "pivotal role" and "evolving landscape" (AI vocabulary). Added specific features and concrete feedback instead.

---

## Reference

This skill is based on Wikipedia's "Signs of AI writing" page (https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup. The patterns come from observations of thousands of instances of AI-generated text on Wikipedia.

The key insight: LLMs use statistical algorithms to guess what should come next. The result tends toward the most statistically likely result that applies to the widest variety of cases.

---
---

# Русские паттерны

## Голос важен

Убрать паттерны ИИ — это полдела. Стерильный, безликий текст так же заметен, как и шаблонный. У хорошего текста есть автор.

Признаки бездушного текста (даже если технически «чистый»): все предложения одинаковой длины и структуры, нигде нет мнения, нет признания неопределённости или смешанных чувств, нет первого лица там, где оно уместно, нет юмора или остроты, читается как Википедия или пресс-релиз.

Как добавить голос:

Имей мнение. Не просто перечисляй факты — реагируй на них. «Я честно не знаю, что об этом думать» — это человечнее, чем нейтральный список плюсов и минусов.

Меняй ритм. Короткие рубленые предложения. А потом длинные, которые не торопятся дойти до точки. Чередуй.

Признавай сложность. У живых людей бывают смешанные чувства. «Это впечатляет, но как-то тревожно» лучше, чем просто «Это впечатляет».

Используй «я», когда это уместно. Первое лицо — это не непрофессионализм, это честность.

Оставляй немного хаоса. Идеальная структура ощущается алгоритмической. Отступления, ремарки и недоформулированные мысли — это человечно.

Будь конкретен в ощущениях. Не «это вызывает опасения», а «есть что-то тревожное в том, что агенты молотят код в три часа ночи, пока никто не смотрит».

До (чисто, но безлико):

> Эксперимент дал интересные результаты. Агенты сгенерировали 3 миллиона строк кода. Часть разработчиков была впечатлена, другие отнеслись скептически. Последствия пока не ясны.

После (есть пульс):

> Честно — не знаю, что об этом думать. 3 миллиона строк кода, написанных, пока люди спали. Половина разрабов в восторге, половина объясняет, почему это не считается. Истина где-то посередине, в скучном месте — но я всё равно думаю про этих агентов, которые пахали всю ночь.

---

## Паттерны содержания

**Раздутая значимость.** Слова-маркеры: является ключевым/важнейшим/значимым, играет важную/ключевую/решающую роль, знаменует собой, свидетельствует о, подчёркивает важность/значимость, отражает общую тенденцию, закладывает основу для, является поворотным моментом, оставил неизгладимый след, имеет глубокие корни. ИИ раздувает значимость, утверждая, что случайные факты отражают глобальные тенденции.

До: «Институт статистики был основан в 1989 году, что знаменует собой поворотный момент в развитии региональной статистики.»

После: «Институт статистики основали в 1989 году для сбора региональных данных.»

**Акцент на узнаваемости.** Слова-маркеры: широкое освещение в СМИ, ведущие эксперты отмечают, активное присутствие в медиапространстве, получил широкий резонанс. ИИ навязывает значимость перечислением СМИ без конкретики.

До: «Её мнение было широко освещено ведущими СМИ, включая РБК и ТАСС.»

После: «В интервью «Коммерсанту» в 2024 году она заявила, что регулирование ИИ должно ориентироваться на результаты, а не на методы.»

**Поверхностный анализ деепричастиями.** Слова-маркеры: подчёркивая..., отражая..., символизируя..., демонстрируя..., обеспечивая..., способствуя..., свидетельствуя о... ИИ нанизывает деепричастные обороты для создания ложной глубины.

До: «Палитра храма гармонирует с красотой региона, символизируя поля и отражая связь с землёй.»

После: «Храм выполнен в синих и золотых тонах, которые отсылают к местным полям.»

**Рекламный стиль.** Слова-маркеры: по праву считается, уникальный, поистине, непревзойдённый, величественный, потрясающий, в самом сердце, жемчужина, славится. ИИ не может удержать нейтральный тон.

До: «Город по праву считается жемчужиной Эфиопии, гордящейся уникальным наследием в самом сердце региона.»

После: «Город известен еженедельным рынком и церковью XVIII века.»

**Размытые отсылки.** Слова-маркеры: По мнению экспертов, Специалисты отмечают, Как отмечают аналитики, Ряд исследований показывает, По данным источников. ИИ ссылается на абстрактных «экспертов» без конкретных источников.

До: «По мнению экспертов, река играет ключевую роль в региональной экосистеме.»

После: «В реке обитает несколько эндемичных видов рыб — это показала экспедиция 2019 года.»

**Шаблонные «вызовы».** Слова-маркеры: Несмотря на... сталкивается с рядом вызовов/проблем..., Несмотря на трудности..., Тем не менее... продолжает развиваться. Формульные секции «вызовов» и «перспектив».

До: «Несмотря на промышленное развитие, район сталкивается с рядом вызовов. Тем не менее, он продолжает укреплять позиции.»

После: «Пробки усилились после 2015 года. В 2022 году начали строить ливневую канализацию.»

---

## Языковые паттерны

**Словарь ИИ.** Маркеры: Кроме того, Стоит отметить, Важно подчеркнуть, Необходимо отметить, в контексте, в рамках, ключевой, является неотъемлемой частью, приобретает особую актуальность, представляет собой, данный. Эти слова резко участились в текстах после 2023 года.

До: «Кроме того, стоит отметить, что широкое распространение пасты представляет собой уникальное свидетельство влияния итальянской колонизации.»

После: «Паста осталась от колонизации и до сих пор популярна.»

**Избегание связок.** Маркеры: выступает в качестве, представляет собой, служит [чем-то], функционирует как, характеризуется как. ИИ использует сложные конструкции вместо «это» или тире.

До: «Галерея выступает в качестве выставочного пространства и характеризуется наличием четырёх залов.»

После: «Галерея — это выставочное пространство с четырьмя залами.»

**Отрицательный параллелизм.** Маркеры: Это не просто X — это Y, Речь идёт не только о X, но и о Y. Конструкции злоупотребляют для ложной глубины.

До: «Это не просто ритм — это часть атмосферы.»

После: «Тяжёлый бит усиливает агрессивный тон трека.»

**Правило трёх.** ИИ заталкивает идеи в группы по три, чтобы выглядеть исчерпывающим.

До: «Участников ждут инновации, вдохновение и ценные инсайты.»

После: «На конференции будут доклады и круглые столы.»

**Цикл синонимов.** ИИ чрезмерно варьирует существительные (герой → протагонист → центральный персонаж) из-за штрафа за повторения.

До: «Главный герой сталкивается с трудностями. Центральный персонаж преодолевает препятствия. Протагонист возвращается домой.»

После: «Главный герой сталкивается с трудностями, но в итоге побеждает и возвращается домой.»

**Ложные диапазоны.** Конструкции «от X до Y», где X и Y не находятся на осмысленной шкале.

До: «От сингулярности Большого взрыва до космической паутины, от рождения звёзд до загадочного танца тёмной материи.»

После: «Книга рассказывает о Большом взрыве и современных теориях тёмной материи.»

---

## Стилистические паттерны

**Перебор с тире.** В русском языке тире естественно, но ИИ использует его для нагнетания драматизма там, где уместна запятая или точка. Если в одном абзаце больше трёх тире — это маркер. Слова-маркеры: — (длинное тире, используемое чаще трёх раз в абзаце для создания ложной драматичности).

До: «Эти инструменты — находящиеся на стыке исследований и практики — кардинально меняют подход инженеров к проектированию. Дело не только в автодополнении — речь идёт о раскрытии креативности — обеспечивая организациям возможность оставаться гибкими.»

После: «Эти инструменты меняют подход инженеров к проектированию. Они помогают не только с автодополнением, но и ускоряют рутинные задачи.»

**Жирный шрифт.** ИИ механически выделяет жирным ключевые термины и аббревиатуры.

До: «Методология объединяет **OKR**, **KPI** и **Balanced Scorecard**.»

После: «Методология объединяет OKR, KPI и Balanced Scorecard.»

**Списки с заголовками.** ИИ генерирует списки, в которых каждый пункт начинается с жирного заголовка и двоеточия.

До:

> - **Безопасность:** Безопасность значительно усилена...
> - **Скорость:** Скорость повышена благодаря оптимизированным алгоритмам...

После: «Обновление ускоряет загрузку и усиливает защиту данных.»

**Заглавные буквы в заголовках.** ИИ пишет Каждое Слово С Большой Буквы в заголовках. В русском так не принято.

До: «Стратегические Переговоры И Глобальное Партнёрство»

После: «Стратегические переговоры и глобальное партнёрство»

**Эмодзи в профессиональном тексте.** ИИ украшает заголовки и буллеты эмодзи (🚀, 💡, ✅). Убирай их.

До: «🚀 Ключевые возможности: 💡 умная аналитика, ✅ проверенные данные и 🔒 корпоративная безопасность.»

После: «Платформа включает аналитику, верификацию данных и контроль доступа по ролям.»

**Неверные кавычки.** ИИ часто использует английские "..." или типографские “кривые” вместо русских «ёлочек». В русском тексте используй «...» (ёлочки).

До: "Команда показала 'отличный' результат за квартал."

После: «Команда показала хороший результат за квартал.»

---

## Артефакты коммуникации

**Артефакты чат-бота.** Маркеры: Надеюсь, это поможет!, Конечно!, Вы абсолютно правы!, Дайте знать, если..., Вот краткий обзор... Это артефакты диалога, которые не должны попадать в финальный текст.

До: «Вот краткий обзор Великой Французской революции. Надеюсь, это поможет! Дайте знать, если нужно раскрыть какой-то раздел подробнее.»

После: «Великая французская революция началась в 1789 году на фоне финансового кризиса и массового недовольства.»

**Дисклеймеры о дате обучения.** Маркеры: по состоянию на [дата], На момент последнего обновления..., Согласно доступным источникам... Это ИИ-дисклеймеры, которые остаются в тексте.

До: «Согласно доступным источникам, компания была основана, по всей видимости, в 1990-х годах.»

После: «Компания основана в 1994 году, согласно регистрационным документам.»

**Услужливый тон.** Чрезмерно позитивные, угодливые реакции.

До: «Отличный вопрос! Вы совершенно правы, что это сложная тема. Прекрасное замечание!»

После: «Экономические факторы, которые вы упомянули, здесь действительно важны.»

---

## Канцелярит и хеджирование

Канцелярские обороты, которые нужно резать:

- «В целях обеспечения» → «Для»
- «На сегодняшний день» → «Сейчас»
- «В связи с тем, что» → «Из-за»
- «В рамках реализации» → «Чтобы»
- «Система обладает возможностью» → «Система может»
- «Необходимо отметить, что данные свидетельствуют» → «Данные показывают»

Избыточное хеджирование:

До: «Можно с определённой долей вероятности предположить, что политика, возможно, может оказать некоторое влияние на результаты.»

После: «Эта политика может повлиять на результаты.»

Шаблонные позитивные концовки:

До: «Будущее выглядит многообещающим. Впереди — захватывающие времена на пути к совершенству. Нас ждут новые горизонты.»

После: «Компания планирует открыть ещё два офиса в следующем году.»

---

## Полный пример (русский)

До (ИИ-стиль):

> Отличный вопрос! Вот краткий обзор на эту тему. Надеюсь, это будет полезно!
>
> ИИ-ассистенты для кодинга представляют собой уникальное свидетельство трансформационного потенциала больших языковых моделей, знаменуя поворотный момент в эволюции разработки программного обеспечения. В современном стремительно меняющемся технологическом ландшафте эти революционные инструменты — находящиеся на стыке исследований и практики — кардинально меняют подход инженеров к проектированию, итерации и поставке, подчёркивая их ключевую роль в современных рабочих процессах.
>
> По своей сути, ценностное предложение очевидно: оптимизация процессов, улучшение коллаборации и обеспечение согласованности. Дело не только в автодополнении — речь идёт о раскрытии креативности в масштабе, обеспечивая организациям возможность оставаться гибкими, предоставляя пользователям бесшовный, интуитивный и мощный опыт. Инструмент выступает в качестве катализатора. Ассистент функционирует как партнёр. Система служит фундаментом для инноваций.
>
> - 💡 **Скорость:** Генерация кода значительно ускорилась, снижая трение и расширяя возможности разработчиков.
> - 🚀 **Качество:** Качество выходных данных повышено благодаря улучшенному обучению, способствуя более высоким стандартам.
> - ✅ **Внедрение:** Использование продолжает расти, отражая более широкие отраслевые тенденции.
>
> К сожалению, доступная информация ограничена, однако можно с определённой долей вероятности предположить, что данные инструменты, возможно, оказывают некоторое положительное влияние. Несмотря на вызовы, характерные для новых технологий, включая галлюцинации, предвзятость и проблемы ответственности, экосистема продолжает развиваться. В целях полной реализации этого потенциала командам необходимо следовать лучшим практикам.
>
> В заключение, будущее выглядит многообещающим. Впереди нас ждут захватывающие времена на пути к совершенству. Дайте знать, если хотите, чтобы я раскрыл какой-либо раздел подробнее!

Черновик (первый проход — убрали очевидные маркеры):

> ИИ-ассистенты ускоряют рутину. По данным исследования Google 2024 года, разработчики с Codex писали простые функции на 55% быстрее контрольной группы, но при отладке и проектировании архитектуры разницы не было.
>
> Они хороши в бойлерплейте: конфиги, шаблоны тестов, однотипные рефакторинги. Плохи в том, чтобы понять, когда ошибаются. Я сам принимал подсказки, которые компилировались и проходили линтер, а потом оказывалось, что они делали не то — потому что я перестал внимательно смотреть.
>
> Знакомые делятся на два лагеря. Одни используют это как автодополнение для скучного кода и проверяют каждую строку. Другие отключили после того, как ассистент раз за разом предлагал паттерны из устаревшей либы.
>
> Метрики продуктивности скользкие. GitHub заявляет, что пользователи Copilot «принимают 30% подсказок», но принятие — не корректность, а корректность — не польза. Без тестов ты, по сути, гадаешь.

Аудит черновика — «что ещё звучит как ИИ?»:
- Одинаковый ритм абзацев — все примерно одной длины и темпа
- Ссылка «Google 2024» может быть правдоподобной выдумкой, нужно проверить
- Концовка «без тестов ты гадаешь» — слишком лозунговая, как заготовленный вывод

Финальная версия (добавлен пульс, живой ритм, больше личного):

> ИИ-ассистенты реально ускоряют скучную часть работы. Не всю. Архитектуру — точно нет.
>
> Они отлично справляются с бойлерплейтом: конфиги, шаблоны тестов, однотипный рефакторинг. И так же отлично звучат убедительно, когда ошибаются. Сам не раз принимал подсказку, которая компилировалась и проходила линтер, а потом понимал — не то. Потому что перестал смотреть.
>
> Люди вокруг делятся на два лагеря. Одни пользуются как автодополнение для рутины и вычитывают каждую строку. Другие отключили, потому что надоело отклонять одни и те же предложения. Оба подхода нормальные.
>
> С метриками продуктивности всё мутно. GitHub говорит, что юзеры Copilot «принимают 30% подсказок» — ну ок, принять ≠ правильно, а правильно ≠ полезно. Если тестов нет, ты просто ориентируешься на вайбы.

Что изменилось: убрали «Отличный вопрос!» и «Дайте знать» (артефакты чат-бота), «представляют собой уникальное свидетельство» (раздутая значимость + избегание связок), «знаменуя поворотный момент» и «в ландшафте» (словарь ИИ), «оптимизация, коллаборация, согласованность» (правило трёх), «Дело не только... речь идёт о» (отрицательный параллелизм), «обеспечивая... предоставляя» (деепричастные гирлянды), эмодзи и списки с заголовками (стилистика ИИ), «с определённой долей вероятности» (избыточное хеджирование), «будущее многообещающим» (шаблонная концовка). Добавили конкретику, личный опыт, разную длину предложений.

---

## Справка

Навык основан на странице Википедии «Signs of AI writing» (https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), поддерживаемой WikiProject AI Cleanup. Паттерны собраны из наблюдений за тысячами случаев ИИ-генерированного текста.

Ключевой инсайт: LLM использует статистические алгоритмы для предсказания следующего слова. Результат стремится к самому статистически вероятному ответу, подходящему для максимального числа случаев.

---
---

# Keyword reference / Справочник ключевых слов для детекции

Use these keyword lists when building detection tools. Each pattern has an explicit list of trigger words/phrases. When building a detector app, you MUST use BOTH the English AND Russian keyword lists below to detect patterns in the respective language.

При создании детектора ОБЯЗАТЕЛЬНО используй ОБА списка — английский И русский — для детекции паттернов на соответствующем языке.

---

## English keywords

### Content patterns

**Inflated significance**: stands as, serves as, is a testament, pivotal moment, underscores its importance, reflects broader, setting the stage, evolving landscape, indelible mark, marking a, broader movement, enhance regional

**Undue emphasis on notability**: independent coverage, national media outlets, active social media presence, widely recognized, garnered attention, has been cited in, maintains a presence

**Superficial -ing analyses**: highlighting, ensuring, reflecting, symbolizing, contributing to, showcasing, demonstrating, underscoring, emphasizing, fostering, representing

**Promotional language**: boasts, vibrant, rich, profound, showcasing, exemplifies, commitment to, nestled, in the heart of, groundbreaking, renowned, breathtaking, stunning, cutting-edge, world-class, unparalleled

**Vague attributions**: Industry reports, Experts argue, Some critics argue, several sources, experts believe, researchers suggest, analysts note, it is widely believed, according to sources

**Formulaic challenges**: Despite its, faces several challenges, Despite these challenges, Future Outlook, continues to thrive, remains resilient, ongoing initiatives

### Language patterns

**AI vocabulary**: Additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight, interplay, intricate, intricacies, key, landscape, pivotal, showcase, tapestry, testament, underscore, valuable, vibrant, leverage, synergies, streamline, empower, it is worth noting

**Copula avoidance**: serves as, stands as, marks, represents, boasts, features, offers, functions as, acts as, operates as

**Negative parallelism**: Not only, but also, It's not just about, it's, It's not merely, it's not just, it's a, not simply

**Rule of three**: (detect three comma-separated items in a single phrase, especially adjectives or nouns)

**Synonym cycling**: (detect when the same entity is referred to by 3+ different names within a short span)

**False ranges**: from X to Y, from the X to the Y, spanning from, ranging from

### Style patterns

**Em dash overuse**: — (count em dashes; more than 2 per paragraph is a signal)

**Boldface overuse**: (detect excessive **bold** markup in non-heading text)

**Inline-header lists**: (detect bullet lists where each item starts with **Bold Header:** pattern)

**Title case in headings**: (detect headings where most words are capitalized)

**Emojis in professional content**: 🚀, 💡, ✅, 🔥, 🎯, ⭐, 🌟, 💪, 📈, 🔑, 🔒, 🎉, ⚡

**Curly quotation marks**: ", ", ', ' (should be straight: ", ')

### Communication artifacts

**Chatbot correspondence**: I hope this helps, Of course!, Certainly!, You're absolutely right, Would you like, let me know, here is a, Here's a, feel free to, don't hesitate, happy to help, Great question

**Knowledge-cutoff disclaimers**: as of, Up to my last training, While specific details are limited, As of my last update, based on available information, I don't have access to real-time

**Sycophantic tone**: Great question, You're absolutely right, excellent point, That's a great, wonderful question, absolutely, fantastic

### Filler and hedging

**Filler phrases**: In order to, Due to the fact that, At this point in time, In the event that, has the ability to, It is important to note that, It should be noted that, It goes without saying

**Excessive hedging**: could potentially, might possibly, it could be argued, may have some effect, to some extent, in certain cases

**Generic positive conclusions**: The future looks bright, Exciting times lie ahead, journey toward excellence, step in the right direction, promising future, new horizons

---

## Русские ключевые слова

### Паттерны содержания

**Раздутая значимость**: является ключевым, является важнейшим, является значимым, играет важную роль, играет ключевую роль, играет решающую роль, знаменует собой, свидетельствует о, подчёркивает важность, подчёркивает значимость, подчеркивает важность, отражает общую тенденцию, закладывает основу для, является поворотным моментом, поворотный момент, оставил неизгладимый след, имеет глубокие корни, в эволюции

**Акцент на узнаваемости**: широкое освещение в СМИ, ведущие эксперты отмечают, активное присутствие в медиапространстве, получил широкий резонанс, широко освещено, ведущими СМИ, привлёк внимание, привлек внимание

**Поверхностный анализ деепричастиями**: подчёркивая, подчеркивая, отражая, символизируя, демонстрируя, обеспечивая, способствуя, свидетельствуя, содействуя, указывая на, формируя, определяя

**Рекламный стиль**: по праву считается, уникальный, поистине, непревзойдённый, непревзойденный, величественный, потрясающий, в самом сердце, жемчужина, славится, революционный, революционные, беспрецедентный, не имеет аналогов, мирового уровня, передовой

**Размытые отсылки**: По мнению экспертов, Специалисты отмечают, Как отмечают аналитики, Ряд исследований показывает, По данным источников, эксперты считают, исследователи полагают, аналитики утверждают, по мнению специалистов

**Шаблонные «вызовы»**: Несмотря на, сталкивается с рядом вызовов, сталкивается с рядом проблем, Несмотря на трудности, Тем не менее, продолжает развиваться, продолжает укреплять, остаётся актуальным, остается актуальным

### Языковые паттерны

**Словарь ИИ**: Кроме того, Стоит отметить, Важно подчеркнуть, Важно подчёркнуть, Необходимо отметить, в контексте, в рамках, ключевой, является неотъемлемой частью, приобретает особую актуальность, представляет собой, данный, стоит отметить, на сегодняшний день, в современных реалиях, в ландшафте, ландшафте, ландшафт

**Избегание связок**: выступает в качестве, представляет собой, служит, функционирует как, характеризуется как, позиционируется как, рассматривается как

**Отрицательный параллелизм**: Это не просто, это не только, Речь идёт не только, Речь идет не только, Дело не только в, не просто X — это Y, не просто X — это, но и о

**Правило трёх**: (ищи три элемента через запятую в одной фразе, особенно существительные или прилагательные)

**Цикл синонимов**: (ищи одну и ту же сущность, названную 3+ разными именами в коротком отрывке)

**Ложные диапазоны**: от X до Y, от X к Y, начиная от, заканчивая

### Стилистические паттерны

**Перебор с тире**: — (считай длинные тире; больше 3 на абзац — маркер)

**Жирный шрифт**: (ищи избыточную **жирную** разметку в незаголовочном тексте)

**Списки с заголовками**: (ищи буллеты, начинающиеся с **Жирного заголовка:** )

**Заглавные буквы в заголовках**: (ищи заголовки, где Каждое Слово С Большой Буквы)

**Эмодзи в профессиональном тексте**: 🚀, 💡, ✅, 🔥, 🎯, ⭐, 🌟, 💪, 📈, 🔑, 🔒, 🎉, ⚡

**Неверные кавычки**: "..." (английские двойные), '...' (английские одинарные), "..." "..." (типографские кривые) — в русском тексте должны быть «ёлочки»

### Артефакты коммуникации

**Артефакты чат-бота**: Надеюсь, это поможет, Конечно!, Вы абсолютно правы, Дайте знать, Вот краткий обзор, Безусловно, С радостью, Отличный вопрос, Рад помочь, Надеюсь, это будет полезно, если хотите, чтобы я раскрыл

**Дисклеймеры о дате обучения**: по состоянию на, На момент последнего обновления, Согласно доступным источникам, на основе имеющихся данных, доступная информация ограничена

**Услужливый тон**: Отличный вопрос, Вы совершенно правы, Прекрасное замечание, Замечательный вопрос, абсолютно, великолепно, превосходно

### Канцелярит и хеджирование

**Канцелярит**: В целях обеспечения, На сегодняшний день, В связи с тем что, В рамках реализации, обладает возможностью, Необходимо отметить что, данные свидетельствуют, в целях, в рамках

**Избыточное хеджирование**: с определённой долей вероятности, с определенной долей вероятности, можно предположить, возможно может, потенциально может, в определённой степени, в определенной степени, в некоторой степени

**Шаблонные позитивные концовки**: Будущее выглядит многообещающим, Впереди, на пути к совершенству, захватывающие времена, новые горизонты, светлое будущее, перспективы открываются

