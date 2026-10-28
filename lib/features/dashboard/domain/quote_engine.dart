// Daily motivation for the Forge dashboard.
//
// A large, offline library of training and mindset quotes with a
// deterministic daily pick: the quote shown for a given day is stable (the
// same day always shows the same quote) and cycles through the whole
// library before any quote repeats.
library;

import 'dashboard_models.dart';

/// Selects the day's quote from the offline library.
abstract final class QuoteEngine {
  QuoteEngine._();

  /// The full, offline quote library (300+ entries).
  static const List<DashboardQuote> library = _quotes;

  /// The quote for [date], chosen deterministically from the library.
  ///
  /// The index is derived from the number of days since the Unix epoch, so
  /// the same calendar day always yields the same quote and the cycle only
  /// repeats after the entire library has been shown.
  static DashboardQuote forDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final index = day.difference(DateTime(1970)).inDays % library.length;
    return library[index];
  }
}

const List<DashboardQuote> _quotes = [
  DashboardQuote(
    'The iron never lies to you. You can walk outside and listen to all kinds of talk, get told that you are a god or a total bastard. The iron will always kick you the real deal.',
    'Henry Rollins',
  ),
  DashboardQuote(
    'No man has the right to be an amateur in the matter of physical training. It is a shame for a man to grow old without seeing the beauty and strength of which his body is capable.',
    'Socrates',
  ),
  DashboardQuote(
    'The body achieves what the mind believes.',
    'Napoleon Hill',
  ),
  DashboardQuote(
    'If you want to change your body, you have to change your mind first.',
    'Unknown',
  ),
  DashboardQuote(
    'Exercise is a celebration of what your body can do, not a punishment for what you ate.',
    'Unknown',
  ),
  DashboardQuote(
    'The only bad workout is the one that did not happen.',
    'Unknown',
  ),
  DashboardQuote(
    'Discipline is doing what you hate to do, but nonetheless doing it like you love it.',
    'Mike Tyson',
  ),
  DashboardQuote(
    'You do not have to be extreme, just consistent.',
    'Unknown',
  ),
  DashboardQuote(
    'The pain you feel today will be the strength you feel tomorrow.',
    'Unknown',
  ),
  DashboardQuote(
    'Success is the sum of small efforts, repeated day in and day out.',
    'Robert Collier',
  ),
  DashboardQuote(
    'What seems impossible today will one day become your warm-up.',
    'Unknown',
  ),
  DashboardQuote(
    'The hard days are what make you. The easy days are just the reward.',
    'Unknown',
  ),
  DashboardQuote(
    'A one-hour workout is 4% of your day. No excuses.',
    'Unknown',
  ),
  DashboardQuote(
    'Push yourself because no one else is going to do it for you.',
    'Unknown',
  ),
  DashboardQuote(
    'You are one workout away from a good mood.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat is fat crying.',
    'Unknown',
  ),
  DashboardQuote(
    'Strong is the new beautiful.',
    'Unknown',
  ),
  DashboardQuote(
    'The struggle you are in today is developing the strength you need for tomorrow.',
    'Robert Tew',
  ),
  DashboardQuote(
    'Do something today that your future self will thank you for.',
    'Sean Patrick Flanery',
  ),
  DashboardQuote(
    'All progress takes place outside the comfort zone.',
    'Michael John Bobak',
  ),
  DashboardQuote(
    'It never gets easier. You just get stronger.',
    'Unknown',
  ),
  DashboardQuote(
    'You are never too old to set another goal or to dream a new dream.',
    'C.S. Lewis',
  ),
  DashboardQuote(
    'The last three or four reps is what makes the muscle grow.',
    'Arnold Schwarzenegger',
  ),
  DashboardQuote(
    'Great things never come from comfort zones.',
    'Unknown',
  ),
  DashboardQuote(
    'Motivation is what gets you started. Habit is what keeps you going.',
    'Jim Ryun',
  ),
  DashboardQuote(
    'The harder you work for something, the greater you will feel when you achieve it.',
    'Unknown',
  ),
  DashboardQuote(
    'Don not stop when you are tired. Stop when you are done.',
    'Unknown',
  ),
  DashboardQuote(
    'Your body can stand almost anything. It is your mind that you have to convince.',
    'Unknown',
  ),
  DashboardQuote(
    'Energy and persistence conquer all things.',
    'Benjamin Franklin',
  ),
  DashboardQuote(
    'The pain of discipline is far lighter than the pain of regret.',
    'Sarah Bombell',
  ),
  DashboardQuote(
    'Be stronger than your strongest excuse.',
    'Unknown',
  ),
  DashboardQuote(
    'Train like a beast, look like a beauty.',
    'Unknown',
  ),
  DashboardQuote(
    'There is no such thing as bad weather, only bad clothing.',
    'Unknown',
  ),
  DashboardQuote(
    'The best project you will ever work on is you.',
    'Unknown',
  ),
  DashboardQuote(
    'A river cuts through rock, not because of its power but because of its persistence.',
    'James N. Watkins',
  ),
  DashboardQuote(
    'Your fitness is 100% mental. Your body will not go where your mind does not take it.',
    'Unknown',
  ),
  DashboardQuote(
    'Some people want it to happen, some wish it would happen, others make it happen.',
    'Michael Jordan',
  ),
  DashboardQuote(
    'Strength does not come from the body. It comes from the will.',
    'Gautama Buddha',
  ),
  DashboardQuote(
    'Fall in love with taking care of yourself, mind, body and spirit.',
    'Tony Robbins',
  ),
  DashboardQuote(
    'When you feel like quitting, think about why you started.',
    'Unknown',
  ),
  DashboardQuote(
    'The difference between who you are and who you want to be is what you do.',
    'Unknown',
  ),
  DashboardQuote(
    'Workout today and thank yourself tomorrow.',
    'Unknown',
  ),
  DashboardQuote(
    'Nothing will work unless you do.',
    'Maya Angelou',
  ),
  DashboardQuote(
    'The body is the only piece of real estate that you have to keep for life.',
    'Unknown',
  ),
  DashboardQuote(
    'Never give up on a dream just because of the time it will take to accomplish it. The time will pass anyway.',
    'Earl Nightingale',
  ),
  DashboardQuote(
    'The secret of getting ahead is getting started.',
    'Mark Twain',
  ),
  DashboardQuote(
    'You may have to fight a battle more than once to win it.',
    'Margaret Thatcher',
  ),
  DashboardQuote(
    'Don not limit your challenges. Challenge your limits.',
    'Unknown',
  ),
  DashboardQuote(
    'Obstacles don not have to stop you. If you run into a wall, don not turn around and give up. Figure out how to climb it, go through it, or work around it.',
    'Michael Jordan',
  ),
  DashboardQuote(
    'I hated every minute of training, but I said, do not quit. Suffer now and live the rest of your life as a champion.',
    'Muhammad Ali',
  ),
  DashboardQuote(
    'The greatest wealth is health.',
    'Virgil',
  ),
  DashboardQuote(
    'Exercise not only changes your body, it changes your mind, your attitude and your mood.',
    'Unknown',
  ),
  DashboardQuote(
    'Once you see results, it becomes an addiction.',
    'Unknown',
  ),
  DashboardQuote(
    'Wake up with determination. Go to bed with satisfaction.',
    'Unknown',
  ),
  DashboardQuote(
    'It is going to be a journey. It is not a sprint to get in shape.',
    'Kenenisa Bekele',
  ),
  DashboardQuote(
    'Self-discipline is the magic power that makes you virtually unstoppable.',
    'Dan Kennedy',
  ),
  DashboardQuote(
    'The mirror is the best accountability partner you will ever have.',
    'Unknown',
  ),
  DashboardQuote(
    'Small daily improvements over time lead to stunning results.',
    'Robin Sharma',
  ),
  DashboardQuote(
    'You do not find the happy life. You make it.',
    'Camilla Eyring Kimball',
  ),
  DashboardQuote(
    'If you are tired of starting over, stop giving up.',
    'Unknown',
  ),
  DashboardQuote(
    'Lifting is a privilege. Make every rep count.',
    'Unknown',
  ),
  DashboardQuote(
    'The grind is real, and so are you.',
    'Unknown',
  ),
  DashboardQuote(
    'Fitness is not about being better than someone else. It is about being better than you used to be.',
    'Unknown',
  ),
  DashboardQuote(
    'Our greatest glory is not in never failing, but in rising every time we fall.',
    'Confucius',
  ),
  DashboardQuote(
    'Your only limit is you.',
    'Unknown',
  ),
  DashboardQuote(
    'Train insane or remain the same.',
    'Unknown',
  ),
  DashboardQuote(
    'I train to be the best version of myself.',
    'Unknown',
  ),
  DashboardQuote(
    'Consistency is the true foundation of trust. Either keep your promise or do not make it.',
    'Roy T. Bennett',
  ),
  DashboardQuote(
    'Rest is part of the training, not the enemy of it.',
    'Unknown',
  ),
  DashboardQuote(
    'You cannot out-train a bad diet, but you can out-discipline one.',
    'Unknown',
  ),
  DashboardQuote(
    'The only place where success comes before work is in the dictionary.',
    'Vidal Sassoon',
  ),
  DashboardQuote(
    'Breathe in determination, breathe out excuses.',
    'Unknown',
  ),
  DashboardQuote(
    'Your mind gives up long before your body does. Trust your body.',
    'Unknown',
  ),
  DashboardQuote(
    'The workout you want to skip is the one you need the most.',
    'Unknown',
  ),
  DashboardQuote(
    'Don not count the days. Make the days count.',
    'Muhammad Ali',
  ),
  DashboardQuote(
    'A year from now you may wish you had started today.',
    'Karen Lamb',
  ),
  DashboardQuote(
    'Strength grows in the moments when you think you can not go on but you keep going anyway.',
    'Unknown',
  ),
  DashboardQuote(
    'Every workout is a deposit in your future bank account.',
    'Unknown',
  ),
  DashboardQuote(
    'There are no shortcuts to any place worth going.',
    'Beverly Sills',
  ),
  DashboardQuote(
    'The person who moves a mountain begins by carrying away small stones.',
    'Confucius',
  ),
  DashboardQuote(
    'Don not wait for the perfect moment. Take the moment and make it perfect.',
    'Unknown',
  ),
  DashboardQuote(
    'You will never always be motivated. You have to learn to be disciplined.',
    'Unknown',
  ),
  DashboardQuote(
    'An ounce of sweat saves a gallon of blood.',
    'George S. Patton',
  ),
  DashboardQuote(
    'If it does not challenge you, it does not change you.',
    'Fred DeVito',
  ),
  DashboardQuote(
    'Hard work beats talent when talent does not work hard.',
    'Tim Notke',
  ),
  DashboardQuote(
    'The man who moves a mountain begins by carrying away small stones.',
    'William Faulkner',
  ),
  DashboardQuote(
    'Sweat more in training, bleed less in battle.',
    'Unknown',
  ),
  DashboardQuote(
    'Winners are not people who never fail, but people who never quit.',
    'Edwin Louis Cole',
  ),
  DashboardQuote(
    'Your health is an investment, not an expense.',
    'Unknown',
  ),
  DashboardQuote(
    'The body you want is hiding underneath the discipline you avoid.',
    'Unknown',
  ),
  DashboardQuote(
    'One day or day one. You decide.',
    'Unknown',
  ),
  DashboardQuote(
    'Focus on progress, not perfection.',
    'Unknown',
  ),
  DashboardQuote(
    'What you do today can improve all your tomorrows.',
    'Ralph Marston',
  ),
  DashboardQuote(
    'Great results are built on the foundation of good habits.',
    'Unknown',
  ),
  DashboardQuote(
    'Train your mind, and the body will follow.',
    'Unknown',
  ),
  DashboardQuote(
    'It is not whether you get knocked down, it is whether you get up.',
    'Vince Lombardi',
  ),
  DashboardQuote(
    'Be the person you needed when you were younger. Strong, disciplined, unstoppable.',
    'Unknown',
  ),
  DashboardQuote(
    'Grit is living like a fire that burns through every obstacle.',
    'Unknown',
  ),
  DashboardQuote(
    'The best time to plant a tree was 20 years ago. The second best time is now.',
    'Chinese Proverb',
  ),
  DashboardQuote(
    'Do not compare your beginning to someone else s middle.',
    'Unknown',
  ),
  DashboardQuote(
    'Every champion was once a contender who refused to give up.',
    'Rocky Balboa',
  ),
  DashboardQuote(
    'Wake up, work out, look hot, kick butt.',
    'Unknown',
  ),
  DashboardQuote(
    'The iron temple is open 24 hours. Show up.',
    'Unknown',
  ),
  DashboardQuote(
    'Pain is temporary. Quitting lasts forever.',
    'Lance Armstrong',
  ),
  DashboardQuote(
    'You have to expect things of yourself before you can do them.',
    'Michael Jordan',
  ),
  DashboardQuote(
    'Discipline equals freedom.',
    'Jocko Willink',
  ),
  DashboardQuote(
    'Be proud of your grind, not ashamed of your sweat.',
    'Unknown',
  ),
  DashboardQuote(
    'Strength is not just physical. It is the will to keep going when your body says stop.',
    'Unknown',
  ),
  DashboardQuote(
    'No excuses. Play like a champion.',
    'Unknown',
  ),
  DashboardQuote(
    'The weight you move today is the mountain you climbed yesterday.',
    'Unknown',
  ),
  DashboardQuote(
    'Champions are made when nobody is watching.',
    'Unknown',
  ),
  DashboardQuote(
    'You are stronger than you think. Prove it.',
    'Unknown',
  ),
  DashboardQuote(
    'The future belongs to those who prepare for it today.',
    'Malcolm X',
  ),
  DashboardQuote(
    'Sweat, sweat, sweat. Discipline is the bridge between goals and accomplishment.',
    'Jim Rohn',
  ),
  DashboardQuote(
    'Do not let what you cannot do interfere with what you can do.',
    'John Wooden',
  ),
  DashboardQuote(
    'A fit body, a calm mind, a house full of love. These things cannot be bought. They must be earned.',
    'Unknown',
  ),
  DashboardQuote(
    'Believe you can and you are halfway there.',
    'Theodore Roosevelt',
  ),
  DashboardQuote(
    'The more you sweat in peace, the less you bleed in war.',
    'Norman Schwarzkopf',
  ),
  DashboardQuote(
    'Motivation gets you going, but habit keeps you growing.',
    'John C. Maxwell',
  ),
  DashboardQuote(
    'You cannot always control what goes on outside, but you can always control what goes on inside.',
    'Wayne Dyer',
  ),
  DashboardQuote(
    'The last rep belongs to the person who did the first one.',
    'Unknown',
  ),
  DashboardQuote(
    'I am not telling you it is going to be easy. I am telling you it is going to be worth it.',
    'Art Williams',
  ),
  DashboardQuote(
    'Your body hears everything your mind says.',
    'Naomi Judd',
  ),
  DashboardQuote(
    'Strength is not silence. It is showing up.',
    'Unknown',
  ),
  DashboardQuote(
    'You have to stay in shape. My grandmother started walking five miles a day when she was sixty.',
    'Will Rogers',
  ),
  DashboardQuote(
    'The gym is the one place where you control your destiny.',
    'Unknown',
  ),
  DashboardQuote(
    'Do it because they said you could not.',
    'Unknown',
  ),
  DashboardQuote(
    'Success is not final, failure is not fatal. It is the courage to continue that counts.',
    'Winston Churchill',
  ),
  DashboardQuote(
    'The heaviest weight in the room is the one you carry in your head.',
    'Unknown',
  ),
  DashboardQuote(
    'Turn your cant into can, and your dreams into plans.',
    'Unknown',
  ),
  DashboardQuote(
    'A one percent improvement every day makes you 37 times better in a year.',
    'Unknown',
  ),
  DashboardQuote(
    'You are the only one who can limit your greatness.',
    'Unknown',
  ),
  DashboardQuote(
    'The victory is not always to the swift, but to those who keep on running.',
    'Unknown',
  ),
  DashboardQuote(
    'Train in the morning like you have something to prove.',
    'Unknown',
  ),
  DashboardQuote(
    'Muscle is built in the gym. Character is built in the grind.',
    'Unknown',
  ),
  DashboardQuote(
    'When you want to succeed as bad as you want to breathe, then you will be successful.',
    'Eric Thomas',
  ),
  DashboardQuote(
    'Your comfort zone is a beautiful place, but nothing ever grows there.',
    'Unknown',
  ),
  DashboardQuote(
    'Leave every workout feeling like you earned the rest that follows.',
    'Unknown',
  ),
  DashboardQuote(
    'The body does not want you to do this. As you run, it tells you to stop. That is what it is there for. It is up to you to push through.',
    'Philipa Ballantine',
  ),
  DashboardQuote(
    'Eat right, train hard, rest well.',
    'Unknown',
  ),
  DashboardQuote(
    'There is no traffic jam on the extra mile.',
    'Zig Ziglar',
  ),
  DashboardQuote(
    'If you want something you have never had, you must be willing to do something you have never done.',
    'Thomas Jefferson',
  ),
  DashboardQuote(
    'The gym is the therapy room where the weight is emotional and the reps are healing.',
    'Unknown',
  ),
  DashboardQuote(
    'Sore today, strong tomorrow.',
    'Unknown',
  ),
  DashboardQuote(
    'Rest when you need it, but never quit.',
    'Unknown',
  ),
  DashboardQuote(
    'The difference between try and triumph is a little umph.',
    'Marvin Phillips',
  ),
  DashboardQuote(
    'Strong people stand up for themselves, but stronger people stand up for others.',
    'Unknown',
  ),
  DashboardQuote(
    'Your workout is a meeting with yourself. Do not cancel.',
    'Unknown',
  ),
  DashboardQuote(
    'It is not about having time. It is about making time.',
    'Unknown',
  ),
  DashboardQuote(
    'The way to get started is to quit talking and begin doing.',
    'Walt Disney',
  ),
  DashboardQuote(
    'Pound the pavement, then own the day.',
    'Unknown',
  ),
  DashboardQuote(
    'A diamond is a chunk of coal that did well under pressure.',
    'Henry Kissinger',
  ),
  DashboardQuote(
    'You are much stronger than you think you are.',
    'Unknown',
  ),
  DashboardQuote(
    'Every rep you skip is a promise you break to yourself.',
    'Unknown',
  ),
  DashboardQuote(
    'Rise and grind. It is time to work.',
    'Unknown',
  ),
  DashboardQuote(
    'The most powerful muscle in your body is your mind.',
    'Unknown',
  ),
  DashboardQuote(
    'Show up for yourself even on the days you do not feel like it.',
    'Unknown',
  ),
  DashboardQuote(
    'You have to be at your strongest when you are at your weakest.',
    'Unknown',
  ),
  DashboardQuote(
    'Good things come to those who sweat.',
    'Unknown',
  ),
  DashboardQuote(
    'Nothing changes until you change.',
    'Unknown',
  ),
  DashboardQuote(
    'The grind is the gym, the reps are the reward, and the sweat is the story.',
    'Unknown',
  ),
  DashboardQuote(
    'Your future self is watching you right now through your memories.',
    'Unknown',
  ),
  DashboardQuote(
    'Conquer your mind and the body will follow.',
    'Unknown',
  ),
  DashboardQuote(
    'I find my soul in the struggle, and I find my strength in the sweat.',
    'Unknown',
  ),
  DashboardQuote(
    'You will not always be motivated, so you must learn to be disciplined.',
    'Unknown',
  ),
  DashboardQuote(
    'Be the change you wish to see in your mirror.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat is the lubricant of progress.',
    'Unknown',
  ),
  DashboardQuote(
    'It hurts up to a point and then it can not hurt anymore. You are stronger than you think.',
    'Unknown',
  ),
  DashboardQuote(
    'Live every day as if it is your last, and train as if your life depends on it.',
    'Unknown',
  ),
  DashboardQuote(
    'No one is going to hand it to you. Earn it.',
    'Unknown',
  ),
  DashboardQuote(
    'The body is a temple, and you are the architect.',
    'Unknown',
  ),
  DashboardQuote(
    'Winners embrace hard work. Losers embrace excuses.',
    'Unknown',
  ),
  DashboardQuote(
    'Doubt kills more dreams than failure ever will.',
    'Suzy Kassem',
  ),
  DashboardQuote(
    'Train your body to look like the future you envisioned.',
    'Unknown',
  ),
  DashboardQuote(
    'Discipline is the strongest form of self-love.',
    'Unknown',
  ),
  DashboardQuote(
    'Soreness is the voice of growth.',
    'Unknown',
  ),
  DashboardQuote(
    'You can either experience the pain of discipline or the pain of regret. The choice is yours.',
    'Unknown',
  ),
  DashboardQuote(
    'Every champion was once a beginner that refused to quit.',
    'Unknown',
  ),
  DashboardQuote(
    'Your only competition is the person you were yesterday.',
    'Unknown',
  ),
  DashboardQuote(
    'The gym does not care how you feel. Show up anyway.',
    'Unknown',
  ),
  DashboardQuote(
    'Fall seven times, stand up eight.',
    'Japanese Proverb',
  ),
  DashboardQuote(
    'I am going to make everything around me beautiful. That will be my life.',
    'Elsie de Wolfe',
  ),
  DashboardQuote(
    'Strength is the journey, not the destination.',
    'Unknown',
  ),
  DashboardQuote(
    'You will not find the fire unless you strike the match.',
    'Unknown',
  ),
  DashboardQuote(
    'Be relentless in your pursuit of a better you.',
    'Unknown',
  ),
  DashboardQuote(
    'The extra mile has no traffic jams.',
    'Unknown',
  ),
  DashboardQuote(
    'If you are going through hell, keep going.',
    'Winston Churchill',
  ),
  DashboardQuote(
    'Progress is impossible without change, and those who cannot change their minds cannot change anything.',
    'George Bernard Shaw',
  ),
  DashboardQuote(
    'Sweat now, shine later.',
    'Unknown',
  ),
  DashboardQuote(
    'Your legs will carry you where your mind goes.',
    'Unknown',
  ),
  DashboardQuote(
    'The secret to getting ahead is getting started and never stopping.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not fear the workout. Fear the version of you that skipped it.',
    'Unknown',
  ),
  DashboardQuote(
    'Every drop of sweat is a step toward your goal.',
    'Unknown',
  ),
  DashboardQuote(
    'You are not stuck. You are in the middle of becoming.',
    'Unknown',
  ),
  DashboardQuote(
    'A champion is someone who gets up even when they cannot.',
    'Jack Dempsey',
  ),
  DashboardQuote(
    'The body remembers every rep. Make them count.',
    'Unknown',
  ),
  DashboardQuote(
    'Hard days build hard bodies.',
    'Unknown',
  ),
  DashboardQuote(
    'Push past the pain and the gain will follow.',
    'Unknown',
  ),
  DashboardQuote(
    'Your mind is a muscle. Train it daily.',
    'Unknown',
  ),
  DashboardQuote(
    'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
    'Aristotle',
  ),
  DashboardQuote(
    'Consistency beats intensity on the days intensity is absent.',
    'Unknown',
  ),
  DashboardQuote(
    'Today I will do what others will not, so tomorrow I can do what others cannot.',
    'Jerry Rice',
  ),
  DashboardQuote(
    'Sweat cleanses the soul.',
    'Unknown',
  ),
  DashboardQuote(
    'The obstacle is the way.',
    'Marcus Aurelius',
  ),
  DashboardQuote(
    'Train with intention. Rest with purpose.',
    'Unknown',
  ),
  DashboardQuote(
    'You can not build a reputation on what you are going to do.',
    'Henry Ford',
  ),
  DashboardQuote(
    'Every set is a promise to yourself.',
    'Unknown',
  ),
  DashboardQuote(
    'Somewhere out there is a version of you that never skips a workout. Be them.',
    'Unknown',
  ),
  DashboardQuote(
    'The weight of yesterday cannot be lifted by the hands of tomorrow. Lift it now.',
    'Unknown',
  ),
  DashboardQuote(
    'Great things never came from a comfort zone. Great bodies neither.',
    'Unknown',
  ),
  DashboardQuote(
    'No matter how slow you go, you are still lapping everyone on the couch.',
    'Unknown',
  ),
  DashboardQuote(
    'Your health account gets rich by the workouts you deposit, not the ones you skip.',
    'Unknown',
  ),
  DashboardQuote(
    'The fight is won or lost far away from witnesses, behind the lines, in the gym, out there on the road, long before I dance under those lights.',
    'Muhammad Ali',
  ),
  DashboardQuote(
    'Be so consistent that your excuses have no voice.',
    'Unknown',
  ),
  DashboardQuote(
    'A strong mind creates a strong body.',
    'Unknown',
  ),
  DashboardQuote(
    'You have been given this body. Honor it with effort.',
    'Unknown',
  ),
  DashboardQuote(
    'Don not wish for it. Work for it.',
    'Unknown',
  ),
  DashboardQuote(
    'The best reward for a good workout is the feeling after it.',
    'Unknown',
  ),
  DashboardQuote(
    'Keep going. The reward is on the other side of the pain.',
    'Unknown',
  ),
  DashboardQuote(
    'The harder the battle, the sweeter the victory.',
    'Les Brown',
  ),
  DashboardQuote(
    'Your future is created by what you do today, not tomorrow.',
    'Robert Kiyosaki',
  ),
  DashboardQuote(
    'Sweat is the price tag on your best self.',
    'Unknown',
  ),
  DashboardQuote(
    'Strength does not come from winning. Your struggles develop your strengths.',
    'Arnold Schwarzenegger',
  ),
  DashboardQuote(
    'One hour of training a day means you still have 23 hours to be lazy. No excuses.',
    'Unknown',
  ),
  DashboardQuote(
    'You are not tired. You are uninspired. Move.',
    'Unknown',
  ),
  DashboardQuote(
    'The dream is free. The hustle is sold separately.',
    'Unknown',
  ),
  DashboardQuote(
    'Break your limits before they break your spirit.',
    'Unknown',
  ),
  DashboardQuote(
    'Every rep is a vote for the person you want to become.',
    'Unknown',
  ),
  DashboardQuote(
    'If it was easy, everyone would be doing it. That is why you are.',
    'Unknown',
  ),
  DashboardQuote(
    'Your body follows where your mind leads. Train the leader.',
    'Unknown',
  ),
  DashboardQuote(
    'The workout ends, but the feeling of accomplishment lasts all day.',
    'Unknown',
  ),
  DashboardQuote(
    'Success walks hand in hand with discipline.',
    'Unknown',
  ),
  DashboardQuote(
    'Be the hardest worker in the room, even when the room is empty.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not watch the clock. Do what it does. Keep going.',
    'Sam Levenson',
  ),
  DashboardQuote(
    'Pain is temporary. Pride is forever.',
    'Unknown',
  ),
  DashboardQuote(
    'Earn your endorphins.',
    'Unknown',
  ),
  DashboardQuote(
    'There is nothing more powerful than a woman who has decided to lift.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat more, regret less.',
    'Unknown',
  ),
  DashboardQuote(
    'The grind does not care about your mood.',
    'Unknown',
  ),
  DashboardQuote(
    'You will never know your strength until you are pushed to your edge.',
    'Unknown',
  ),
  DashboardQuote(
    'Every day is a chance to get better.',
    'Unknown',
  ),
  DashboardQuote(
    'Stop wishing, start working.',
    'Unknown',
  ),
  DashboardQuote(
    'The body achieves what the mind commits to.',
    'Unknown',
  ),
  DashboardQuote(
    'A minute of pain is worth a lifetime of glory.',
    'Unknown',
  ),
  DashboardQuote(
    'Lifting heavy is a luxury. Enjoy the privilege.',
    'Unknown',
  ),
  DashboardQuote(
    'Your only failure is not trying.',
    'Unknown',
  ),
  DashboardQuote(
    'Be the best version of yourself that ever lived.',
    'Unknown',
  ),
  DashboardQuote(
    'The gym is my sanctuary, and the bar is my altar.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat is the finest perfume.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not give up at the half-way point. The best is yet to come.',
    'Unknown',
  ),
  DashboardQuote(
    'Control your diet, your sleep and your training, and the results will control themselves.',
    'Unknown',
  ),
  DashboardQuote(
    'Courage is the ability to do what you are afraid to do. Show up scared, then lift.',
    'Unknown',
  ),
  DashboardQuote(
    'You have more strength in you than you have ever used.',
    'Unknown',
  ),
  DashboardQuote(
    'The only easy day was yesterday.',
    'Navy SEALs',
  ),
  DashboardQuote(
    'Win the morning, win the day.',
    'Unknown',
  ),
  DashboardQuote(
    'Your habits write the story of your body.',
    'Unknown',
  ),
  DashboardQuote(
    'Never let a bad day turn into a bad week.',
    'Unknown',
  ),
  DashboardQuote(
    'The scale is not the judge. Your effort is.',
    'Unknown',
  ),
  DashboardQuote(
    'Be hungry in the gym so you are never hungry in life.',
    'Unknown',
  ),
  DashboardQuote(
    'The greatest battle you will ever fight is with yourself, and you are winning.',
    'Unknown',
  ),
  DashboardQuote(
    'Every workout is a small war you win against inertia.',
    'Unknown',
  ),
  DashboardQuote(
    'You are never done. You are always becoming.',
    'Unknown',
  ),
  DashboardQuote(
    'Fall in love with the process, and the results will follow.',
    'Unknown',
  ),
  DashboardQuote(
    'The bar does not move unless you make it move.',
    'Unknown',
  ),
  DashboardQuote(
    'Your muscles remember the days you showed up.',
    'Unknown',
  ),
  DashboardQuote(
    'Run from your excuses and run to your goals.',
    'Unknown',
  ),
  DashboardQuote(
    'A strong body is a quiet prayer for a long, capable life.',
    'Unknown',
  ),
  DashboardQuote(
    'You do not rise to the level of your goals. You fall to the level of your systems.',
    'James Clear',
  ),
  DashboardQuote(
    'The reps you do not want to do are the reps that count.',
    'Unknown',
  ),
  DashboardQuote(
    'Tough times never last, but tough people do.',
    'Robert H. Schuller',
  ),
  DashboardQuote(
    'Your workout is not a punishment. It is a privilege.',
    'Unknown',
  ),
  DashboardQuote(
    'Make yourself a priority, because you are worth the effort.',
    'Unknown',
  ),
  DashboardQuote(
    'The sweat of today is the strength of tomorrow.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not save your best for the last rep. Give it every rep.',
    'Unknown',
  ),
  DashboardQuote(
    'When the weights get heavy, the excuses get light.',
    'Unknown',
  ),
  DashboardQuote(
    'Every setback is a setup for a comeback.',
    'Unknown',
  ),
  DashboardQuote(
    'You are one decision away from a different life. Decide to train.',
    'Unknown',
  ),
  DashboardQuote(
    'The only workout you regret is the one you skipped.',
    'Unknown',
  ),
  DashboardQuote(
    'Strength is the best accessory.',
    'Unknown',
  ),
  DashboardQuote(
    'Let the barbell teach you discipline.',
    'Unknown',
  ),
  DashboardQuote(
    'You carry your body every day. Carry it well.',
    'Unknown',
  ),
  DashboardQuote(
    'The mirror rewards those who show up.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not let a rest day become a rest month.',
    'Unknown',
  ),
  DashboardQuote(
    'Your diet is 80% of the fight, and your training is the 20% that makes you strong.',
    'Unknown',
  ),
  DashboardQuote(
    'The best view comes after the hardest climb. So do the sets.',
    'Unknown',
  ),
  DashboardQuote(
    'You are stronger than your excuses, faster than your fears and braver than your doubts.',
    'Unknown',
  ),
  DashboardQuote(
    'Every day you train, you are sculpting your future self.',
    'Unknown',
  ),
  DashboardQuote(
    'The weight room does not care who you were yesterday.',
    'Unknown',
  ),
  DashboardQuote(
    'Success is built in the hours nobody is watching.',
    'Unknown',
  ),
  DashboardQuote(
    'A body in motion stays in motion. Start.',
    'Unknown',
  ),
  DashboardQuote(
    'Repetition builds the champion.',
    'Unknown',
  ),
  DashboardQuote(
    'You cannot buy health, but you can earn it.',
    'Unknown',
  ),
  DashboardQuote(
    'Be too strong to be held down by a bad day.',
    'Unknown',
  ),
  DashboardQuote(
    'The grind is your friend. The excuses are your enemy.',
    'Unknown',
  ),
  DashboardQuote(
    'Your future self will thank your present self for the effort.',
    'Unknown',
  ),
  DashboardQuote(
    'Lift to live, and live to lift.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat now so you can smile later.',
    'Unknown',
  ),
  DashboardQuote(
    'Nobody ever built a statue to honor a critic. Build your body.',
    'Unknown',
  ),
  DashboardQuote(
    'You are the architect of your own transformation.',
    'Unknown',
  ),
  DashboardQuote(
    'The bar is heavy, but so is your potential.',
    'Unknown',
  ),
  DashboardQuote(
    'Every muscle in your body is a memory of a workout you did not skip.',
    'Unknown',
  ),
  DashboardQuote(
    'Hustle until your haters ask if you are hiring.',
    'Unknown',
  ),
  DashboardQuote(
    'A healthy outside starts from the inside.',
    'Robert Urich',
  ),
  DashboardQuote(
    'Train your body like it is your only vehicle to your dreams.',
    'Unknown',
  ),
  DashboardQuote(
    'The voice that says you cannot is lying.',
    'Unknown',
  ),
  DashboardQuote(
    'Consistency is the mother of mastery.',
    'Unknown',
  ),
  DashboardQuote(
    'Choose the pain of discipline over the pain of regret.',
    'Unknown',
  ),
  DashboardQuote(
    'Your strongest set is the one you show up for.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not wait for inspiration. Create it with action.',
    'Unknown',
  ),
  DashboardQuote(
    'The gym is full of people starting from where you are. Keep going.',
    'Unknown',
  ),
  DashboardQuote(
    'You will never regret a workout. You will always regret a skip.',
    'Unknown',
  ),
  DashboardQuote(
    'The body was made to be tested. Test it kindly.',
    'Unknown',
  ),
  DashboardQuote(
    'Discipline is doing the work when the applause is silent.',
    'Unknown',
  ),
  DashboardQuote(
    'A strong heart beats under a strong chest. Build both.',
    'Unknown',
  ),
  DashboardQuote(
    'Every step of the journey is a step toward your best self.',
    'Unknown',
  ),
  DashboardQuote(
    'The fire inside you is bigger than the fire outside.',
    'Unknown',
  ),
  DashboardQuote(
    'Train like you have something to prove, because you do.',
    'Unknown',
  ),
  DashboardQuote(
    'Your body is a canvas and your workouts are the brush.',
    'Unknown',
  ),
  DashboardQuote(
    'The only way to find your limits is to touch them.',
    'Unknown',
  ),
  DashboardQuote(
    'Keep the promises you make to the barbell.',
    'Unknown',
  ),
  DashboardQuote(
    'A runner does not stop when it starts to rain. Neither do you.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat is a gift you give to your future self.',
    'Unknown',
  ),
  DashboardQuote(
    'You cannot fall if you keep climbing.',
    'Unknown',
  ),
  DashboardQuote(
    'The strongest people are not always the loudest. They just show up.',
    'Unknown',
  ),
  DashboardQuote(
    'Make your body a fortress.',
    'Unknown',
  ),
  DashboardQuote(
    'Progress is measured in reps, not in wishes.',
    'Unknown',
  ),
  DashboardQuote(
    'The hardest lift of the day is getting off the couch.',
    'Unknown',
  ),
  DashboardQuote(
    'Your muscles are built on the days you want to quit.',
    'Unknown',
  ),
  DashboardQuote(
    'There is no finish line, only the next rep.',
    'Unknown',
  ),
  DashboardQuote(
    'Every champion carries scars from battles won.',
    'Unknown',
  ),
  DashboardQuote(
    'Lift heavy, live light.',
    'Unknown',
  ),
  DashboardQuote(
    'The pain of today is the power of tomorrow.',
    'Unknown',
  ),
  DashboardQuote(
    'Never underestimate the power of showing up.',
    'Unknown',
  ),
  DashboardQuote(
    'Your body is the only place you have to live. Make it comfortable.',
    'Unknown',
  ),
  DashboardQuote(
    'Rest is not a reward. It is a requirement for growth.',
    'Unknown',
  ),
  DashboardQuote(
    'The best proof of discipline is an honest log.',
    'Unknown',
  ),
  DashboardQuote(
    'Strong people do not need to prove anything, but they do anyway.',
    'Unknown',
  ),
  DashboardQuote(
    'Every repetition brings you closer to the person you want to become.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not let the heaviness of life stop you from lifting.',
    'Unknown',
  ),
  DashboardQuote(
    'Your effort is the only thing you fully control. Spend it wisely.',
    'Unknown',
  ),
  DashboardQuote(
    'The iron remembers. So will you.',
    'Unknown',
  ),
  DashboardQuote(
    'A goal without a plan is just a wish. Your split is the plan.',
    'Unknown',
  ),
  DashboardQuote(
    'Train your weaknesses so they become your strengths.',
    'Unknown',
  ),
  DashboardQuote(
    'The body you want respects the effort you give.',
    'Unknown',
  ),
  DashboardQuote(
    'There is a warrior inside you. Feed it iron.',
    'Unknown',
  ),
  DashboardQuote(
    'You do not need more time. You need more action.',
    'Unknown',
  ),
  DashboardQuote(
    'The finish line is always one more rep away.',
    'Unknown',
  ),
  DashboardQuote(
    'Strength is never wasted. It compounds like interest.',
    'Unknown',
  ),
  DashboardQuote(
    'The mirror is honest. Train so it has nothing bad to say.',
    'Unknown',
  ),
  DashboardQuote(
    'Today is a gift. Spend it in the gym.',
    'Unknown',
  ),
  DashboardQuote(
    'Be patient with the process and relentless with the effort.',
    'Unknown',
  ),
  DashboardQuote(
    'Your legs carry more than your body. They carry your will.',
    'Unknown',
  ),
  DashboardQuote(
    'Every drop of sweat waters the garden of your goals.',
    'Unknown',
  ),
  DashboardQuote(
    'The person who wins is the one who trains on the days they do not feel like it.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat is proof that you showed up.',
    'Unknown',
  ),
  DashboardQuote(
    'Let your training be louder than your excuses.',
    'Unknown',
  ),
  DashboardQuote(
    'A body built in the dark is a body that shines in the light.',
    'Unknown',
  ),
  DashboardQuote(
    'You are not behind. You are right on time.',
    'Unknown',
  ),
  DashboardQuote(
    'The weight does not care about your story. It only respects your effort.',
    'Unknown',
  ),
  DashboardQuote(
    'Strong back, strong life.',
    'Unknown',
  ),
  DashboardQuote(
    'Never skip the session that makes you uncomfortable.',
    'Unknown',
  ),
  DashboardQuote(
    'The body follows the mind that wills it.',
    'Unknown',
  ),
  DashboardQuote(
    'Train like every rep is a brick in the house of your future.',
    'Unknown',
  ),
  DashboardQuote(
    'You are the author of your own strength story.',
    'Unknown',
  ),
  DashboardQuote(
    'The greatest room in the world is the room for improvement.',
    'Unknown',
  ),
  DashboardQuote(
    'Keep your standards high and your excuses low.',
    'Unknown',
  ),
  DashboardQuote(
    'The sweat is worth it. The mirror will agree.',
    'Unknown',
  ),
  DashboardQuote(
    'Be a savage in the gym and a saint outside it.',
    'Unknown',
  ),
  DashboardQuote(
    'The journey of a thousand reps begins with a single set.',
    'Unknown',
  ),
  DashboardQuote(
    'Your health is your wealth. Invest in it daily.',
    'Unknown',
  ),
  DashboardQuote(
    'The only person you have to be better than is who you were yesterday.',
    'Unknown',
  ),
  DashboardQuote(
    'Train your grip, and you will never let go of your goals.',
    'Unknown',
  ),
  DashboardQuote(
    'Every day without a workout is a day without progress.',
    'Unknown',
  ),
  DashboardQuote(
    'Rise up. The iron is waiting.',
    'Unknown',
  ),
  DashboardQuote(
    'Be the reason your excuses are unemployed.',
    'Unknown',
  ),
  DashboardQuote(
    'The body is not just the shell of the soul. It is its workout partner.',
    'Unknown',
  ),
  DashboardQuote(
    'You are one workout away from a better day.',
    'Unknown',
  ),
  DashboardQuote(
    'Champions train, losers complain.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat is the shortcut to confidence.',
    'Unknown',
  ),
  DashboardQuote(
    'The grind does not promise comfort, but it pays in progress.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not be afraid to lift heavy things. You were built for it.',
    'Unknown',
  ),
  DashboardQuote(
    'Your best set is your next set.',
    'Unknown',
  ),
  DashboardQuote(
    'The path to greatness is paved with early mornings and heavy reps.',
    'Unknown',
  ),
  DashboardQuote(
    'A workout a day keeps the regrets away.',
    'Unknown',
  ),
  DashboardQuote(
    'You are stronger than the storm in your head.',
    'Unknown',
  ),
  DashboardQuote(
    'Leave your excuses at the door of the gym.',
    'Unknown',
  ),
  DashboardQuote(
    'The body is a promise you make to yourself every day.',
    'Unknown',
  ),
  DashboardQuote(
    'Never confuse a single defeat with a final defeat.',
    'F. Scott Fitzgerald',
  ),
  DashboardQuote(
    'Your sweat is your superpower.',
    'Unknown',
  ),
  DashboardQuote(
    'Keep showing up. That is the whole secret.',
    'Unknown',
  ),
  DashboardQuote(
    'A strong man is a man who has nothing to prove and everything to earn.',
    'Unknown',
  ),
  DashboardQuote(
    'The bar is a teacher. Learn from every lift.',
    'Unknown',
  ),
  DashboardQuote(
    'Your body will go where your will directs it.',
    'Unknown',
  ),
  DashboardQuote(
    'Sweat is the ink in which your success story is written.',
    'Unknown',
  ),
  DashboardQuote(
    'Discipline is the bridge between who you are and who you want to be.',
    'Unknown',
  ),
  DashboardQuote(
    'Do not count the minutes of your workout. Make the minutes count.',
    'Unknown',
  ),
  DashboardQuote(
    'The strongest chains are forged in the hottest fire.',
    'Unknown',
  ),
  DashboardQuote(
    'You are not tired. You are just not done yet.',
    'Unknown',
  ),
  DashboardQuote(
    'Train to be dangerous, rest to be kind, eat to be strong.',
    'Unknown',
  ),
  DashboardQuote(
    'The body is the most honest mirror in the world.',
    'Unknown',
  ),
  DashboardQuote(
    'Every rep you finish makes the next one easier.',
    'Unknown',
  ),
  DashboardQuote(
    'Your future is built on the shoulders of today is effort.',
    'Unknown',
  ),
];
