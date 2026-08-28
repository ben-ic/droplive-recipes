import { createHash } from 'node:crypto';

const base = 'http://127.0.0.1:3003';
const password = process.env.LIFTTRACE_OWNER_PASSWORD;
let token = '';
let ownerId = null;

function isoDate(date) {
  return date.toISOString().slice(0, 10);
}

function daysAgo(count) {
  const date = new Date();
  date.setUTCHours(12, 0, 0, 0);
  date.setUTCDate(date.getUTCDate() - count);
  return isoDate(date);
}

function uuidFor(value) {
  const hex = createHash('sha256').update(`droplive-lifttrace:${value}`).digest('hex').slice(0, 32).split('');
  hex[12] = '4';
  hex[16] = '8';
  const joined = hex.join('');
  return `${joined.slice(0, 8)}-${joined.slice(8, 12)}-${joined.slice(12, 16)}-${joined.slice(16, 20)}-${joined.slice(20)}`;
}

async function request(path, { method = 'GET', body, auth = true } = {}) {
  const headers = { 'Content-Type': 'application/json' };
  if (auth && token) headers.Authorization = `Bearer ${token}`;
  const response = await fetch(`${base}${path}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let data = null;
  try { data = text ? JSON.parse(text) : null; } catch {}
  if (!response.ok) {
    throw new Error(`${method} ${path} returned ${response.status}: ${data?.error || text}`);
  }
  return data;
}

async function waitForServer() {
  for (let attempt = 0; attempt < 90; attempt += 1) {
    try {
      const response = await fetch(`${base}/api/auth/status`);
      if (response.ok) return;
    } catch {}
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  throw new Error('LiftTrace did not become ready within 90 seconds');
}

async function signIn() {
  const status = await request('/api/auth/status', { auth: false });
  if (status.setup_required) {
    const registered = await request('/api/auth/register', {
      method: 'POST',
      auth: false,
      body: {
        username: 'lucas',
        password,
        full_name: 'Lucas Meyer',
        nickname: 'Lucas',
        email: 'lucas@northstar-relay.droplive.test',
        birthday: '1991-04-18',
        gender: 'male',
      },
    });
    token = registered.token;
    ownerId = registered.user.id;
  } else {
    const loggedIn = await request('/api/auth/login', {
      method: 'POST',
      auth: false,
      body: { username: 'lucas', password },
    });
    token = loggedIn.token;
    ownerId = loggedIn.user.id;
  }
  if (!token) throw new Error('LiftTrace did not return an owner session token');
  if (!ownerId) throw new Error('LiftTrace did not return the owner account id');
}

const EXERCISES = [
  { name: 'Barbell Back Squat', category: 'strength', primary_muscles: ['quadriceps', 'gluteal'], secondary_muscles: ['hamstring', 'lower-back'], equipment: ['barbell', 'rack'], load_type: 'bilateral', instructions: 'Brace before each rep, keep the bar over mid-foot, and drive evenly through both legs.', tips: 'Use the same stance for every working set and stop one rep before form changes.' },
  { name: 'Barbell Bench Press', category: 'strength', primary_muscles: ['chest'], secondary_muscles: ['triceps', 'deltoids'], equipment: ['barbell', 'bench'], load_type: 'bilateral', instructions: 'Set the shoulder blades, touch the lower chest under control, and press toward the rack.', tips: 'Keep both feet planted and use a consistent pause.' },
  { name: 'Conventional Deadlift', category: 'strength', primary_muscles: ['hamstring', 'gluteal', 'lower-back'], secondary_muscles: ['upper-back', 'forearm'], equipment: ['barbell'], load_type: 'bilateral', instructions: 'Set the brace before the pull and keep the bar close from floor to lockout.', tips: 'Reset the start position between reps.' },
  { name: 'Standing Overhead Press', category: 'strength', primary_muscles: ['deltoids'], secondary_muscles: ['triceps', 'abs'], equipment: ['barbell'], load_type: 'bilateral', instructions: 'Brace the trunk, press in a straight path, and finish with the bar over the shoulders.', tips: 'Do not turn the final reps into a standing incline press.' },
  { name: 'Chest-Supported Row', category: 'strength', primary_muscles: ['upper-back'], secondary_muscles: ['biceps', 'trapezius'], equipment: ['dumbbells', 'bench'], load_type: 'paired', instructions: 'Keep the chest on the pad and pull the elbows toward the hips.', tips: 'Pause briefly at the top without lifting the torso.' },
  { name: 'Romanian Deadlift', category: 'strength', primary_muscles: ['hamstring', 'gluteal'], secondary_muscles: ['lower-back'], equipment: ['barbell'], load_type: 'bilateral', instructions: 'Push the hips back while the bar stays close to the thighs.', tips: 'End the descent when the hamstrings reach a firm stretch.' },
  { name: 'Pull-Up', category: 'strength', primary_muscles: ['upper-back'], secondary_muscles: ['biceps', 'forearm'], equipment: ['pull-up bar'], load_type: 'bilateral', instructions: 'Start from a controlled hang and pull the chest toward the bar.', tips: 'Keep the ribs down and avoid swinging.' },
  { name: 'Bulgarian Split Squat', category: 'strength', primary_muscles: ['quadriceps', 'gluteal'], secondary_muscles: ['adductors'], equipment: ['dumbbells', 'bench'], load_type: 'paired', instructions: 'Lower the back knee under control and keep pressure through the whole front foot.', tips: 'Use the rack for balance if it helps keep the work on the front leg.' },
  { name: 'Incline Dumbbell Press', category: 'strength', primary_muscles: ['chest'], secondary_muscles: ['deltoids', 'triceps'], equipment: ['dumbbells', 'bench'], load_type: 'paired', instructions: 'Lower the dumbbells beside the upper chest and press them on a stable path.', tips: 'Keep the bench at a low incline to limit shoulder strain.' },
  { name: 'Cable Face Pull', category: 'accessory', primary_muscles: ['deltoids', 'upper-back'], secondary_muscles: ['trapezius'], equipment: ['cable'], load_type: 'bilateral', instructions: 'Pull toward eye level while the upper arms stay high.', tips: 'Use a light load and finish every rep with external rotation.' },
  { name: 'Standing Calf Raise', category: 'accessory', primary_muscles: ['calves'], secondary_muscles: [], equipment: ['machine'], load_type: 'bilateral', instructions: 'Use a full stretch at the bottom and a clear pause at the top.', tips: 'Do not bounce out of the bottom position.' },
  { name: 'Pallof Press', category: 'core', primary_muscles: ['abs', 'obliques'], secondary_muscles: ['gluteal'], equipment: ['cable'], load_type: 'bilateral', instructions: 'Press the handle away without letting the torso rotate.', tips: 'Use a stance that lets the trunk, not the arms, limit the set.' },
];

const PLAN = [
  { name: 'Foundation A — Squat', day: 'Monday', exercises: [['Barbell Back Squat', 4, '5', 82.5], ['Barbell Bench Press', 4, '6', 62.5], ['Chest-Supported Row', 3, '10', 22], ['Pallof Press', 3, '12', 12]] },
  { name: 'Foundation B — Pull', day: 'Wednesday', exercises: [['Conventional Deadlift', 3, '5', 105], ['Standing Overhead Press', 4, '6', 37.5], ['Pull-Up', 3, '8', 0], ['Cable Face Pull', 3, '15', 18]] },
  { name: 'Foundation C — Volume', day: 'Friday', exercises: [['Romanian Deadlift', 3, '8', 70], ['Incline Dumbbell Press', 3, '10', 20], ['Bulgarian Split Squat', 3, '10', 18], ['Standing Calf Raise', 4, '12', 55]] },
];

async function seedExercises() {
  const current = await request('/api/exercises?limit=500');
  const rows = Array.isArray(current) ? current : (current.exercises || []);
  const byName = new Map(rows.map(row => [row.name, row]));
  for (const spec of EXERCISES) {
    if (!byName.has(spec.name)) {
      const created = await request('/api/exercises', { method: 'POST', body: spec });
      byName.set(created.name, created);
    }
  }
  return byName;
}

async function seedProgram(exercises) {
  const programs = await request('/api/programs');
  let program = programs.find(row => row.name === 'Northstar Foundation Cycle');
  if (!program) {
    program = await request('/api/programs', {
      method: 'POST',
      body: {
        name: 'Northstar Foundation Cycle',
        description: 'A twelve-week strength block built around three repeatable sessions, steady load increases, and controlled effort.',
        goal: 'strength',
        visibility: 'private',
        duration_weeks: 12,
        advance_mode: 'calendar',
        on_complete: 'hold',
      },
    });
  }
  const detail = await request(`/api/programs/${program.id}`);
  const templates = new Map(detail.templates.map(row => [row.name, row]));
  for (const session of PLAN) {
    if (!templates.has(session.name)) {
      const body = {
        program_id: program.id,
        name: session.name,
        day_label: session.day,
        exercises: session.exercises.map(([name, sets, reps, weight]) => ({
          uuid: uuidFor(`template:${session.name}:${name}`),
          exercise_id: exercises.get(name).id,
          exercise_name: name,
          target_sets: sets,
          target_reps: reps,
          target_weight: weight,
          rest_sec: name.includes('Squat') || name.includes('Deadlift') || name.includes('Bench Press') ? 180 : 90,
        })),
      };
      templates.set(session.name, await request('/api/templates', { method: 'POST', body }));
    }
  }
  await request(`/api/programs/${program.id}/assign`, {
    method: 'POST',
    body: { user_id: ownerId, start_date: daysAgo(84), make_active: true },
  });
  return { program, templates };
}

function completedExercise(exercises, entry, week, exerciseIndex, date) {
  const [name, count, targetReps, baseWeight] = entry;
  const reps = Number(targetReps);
  const increase = name === 'Conventional Deadlift' ? week * 2.5
    : name.includes('Squat') || name.includes('Bench Press') || name.includes('Overhead') || name.includes('Romanian') ? Math.floor(week / 2) * 2.5
    : name === 'Pull-Up' ? 0 : Math.floor(week / 3);
  const weight = baseWeight ? baseWeight + increase : 0;
  return {
    uuid: uuidFor(`workout:${date}:${name}`),
    exercise_id: exercises.get(name).id,
    exercise_name: name,
    target_sets: count,
    target_reps: targetReps,
    target_weight: weight,
    notes: week === 7 && exerciseIndex === 0 ? 'Deload week: clean reps and a controlled final set.' : '',
    sets: Array.from({ length: count }, (_, setIndex) => ({
      uuid: uuidFor(`workout:${date}:${name}:set:${setIndex + 1}`),
      number: setIndex + 1,
      weight: week === 7 ? Math.max(0, weight - 5) : weight,
      reps: week === 11 && setIndex === count - 1 ? Math.max(3, reps - 1) : reps,
      rpe: Math.min(9, 6.5 + week * 0.18 + setIndex * 0.2),
      completed: true,
      warmup: false,
    })),
  };
}

async function seedWorkouts(exercises, program, templates) {
  const today = new Date();
  today.setUTCHours(12, 0, 0, 0);
  const start = new Date(today);
  start.setUTCDate(start.getUTCDate() - 84);
  const desiredWeekday = [1, 3, 5];
  const notes = [
    'Smooth tempo. All working sets stayed inside the planned effort range.',
    'Good bar speed. Kept one repetition in reserve on the final compound set.',
    'Volume session complete. Left knee and shoulder both felt normal.',
  ];
  for (let day = new Date(start); day < today; day.setUTCDate(day.getUTCDate() + 1)) {
    const sessionIndex = desiredWeekday.indexOf(day.getUTCDay());
    if (sessionIndex < 0) continue;
    const elapsedDays = Math.floor((day - start) / 86400000);
    const week = Math.min(11, Math.floor(elapsedDays / 7));
    const session = PLAN[sessionIndex];
    const template = templates.get(session.name);
    await request(`/api/workout/${isoDate(day)}`, {
      method: 'PUT',
      body: {
        template_id: template.id,
        program_id: program.id,
        program_week: week + 1,
        name: session.name,
        exercises: session.exercises.map((entry, index) => completedExercise(exercises, entry, week, index, isoDate(day))),
        notes: notes[sessionIndex],
        duration_min: 58 + sessionIndex * 7 + (week % 3) * 3,
        completed: true,
      },
    });
  }

  const next = PLAN[today.getUTCDay() % PLAN.length];
  const nextTemplate = templates.get(next.name);
  await request(`/api/workout/${isoDate(today)}`, {
    method: 'PUT',
    body: {
      template_id: nextTemplate.id,
      program_id: program.id,
      program_week: 12,
      name: `${next.name} — Today`,
      exercises: next.exercises.map(([name, count, reps, weight]) => ({
        uuid: uuidFor(`workout:${isoDate(today)}:${name}`),
        exercise_id: exercises.get(name).id,
        exercise_name: name,
        target_sets: count,
        target_reps: reps,
        target_weight: weight ? weight + 10 : 0,
        sets: Array.from({ length: count }, (_, index) => ({ uuid: uuidFor(`workout:${isoDate(today)}:${name}:set:${index + 1}`), number: index + 1, weight: weight ? weight + 10 : 0, reps: Number(reps), rpe: null, completed: false, warmup: false })),
      })),
      notes: 'Planned session: keep the first work set conservative, then use the final set to confirm next block targets.',
      duration_min: null,
      completed: false,
    },
  });
}

async function seedBodyAndCardio() {
  for (let week = 12; week >= 0; week -= 1) {
    const date = daysAgo(week * 7);
    const progress = 12 - week;
    await request(`/api/body-stats/${date}`, {
      method: 'PUT',
      body: { stats: {
        weight: Math.round((82.4 - progress * 0.17) * 10) / 10,
        bodyFat: Math.round((18.6 - progress * 0.12) * 10) / 10,
        waist: Math.round((87.5 - progress * 0.22) * 10) / 10,
        chest: Math.round((101.2 + progress * 0.1) * 10) / 10,
        hips: Math.round((99.4 - progress * 0.08) * 10) / 10,
      } },
    });
  }

  const current = await request('/api/cardio');
  const keys = new Set(current.map(row => `${row.date}|${row.activity}`));
  for (let week = 11; week >= 0; week -= 1) {
    const date = daysAgo(week * 7 + 1);
    const activity = week % 3 === 0 ? 'Easy bike recovery' : 'Zone 2 run';
    if (keys.has(`${date}|${activity}`)) continue;
    await request('/api/cardio', {
      method: 'POST',
      body: {
        date,
        activity,
        duration_min: activity.startsWith('Easy') ? 32 : 38 + (week % 4) * 2,
        distance: activity.startsWith('Easy') ? 12.4 + (11 - week) * 0.2 : 5.4 + (11 - week) * 0.08,
        distance_unit: 'km',
        avg_hr: activity.startsWith('Easy') ? 122 : 138,
        notes: 'Conversational pace with steady breathing; used as recovery work between strength sessions.',
        is_template: week === 0,
      },
    });
  }
}

async function verify(exercises) {
  const recent = await request('/api/workout/recent?limit=60');
  const body = await request(`/api/body-stats/range?start=${daysAgo(100)}&end=${daysAgo(0)}`);
  const cardio = await request(`/api/cardio?start=${daysAgo(100)}&end=${daysAgo(0)}`);
  const records = await request('/api/stats/records');
  if (exercises.size < 12 || recent.length < 30 || body.length < 12 || cardio.length < 10 || records.length < 8) {
    throw new Error(`seed verification failed: exercises=${exercises.size} workouts=${recent.length} body=${body.length} cardio=${cardio.length} records=${records.length}`);
  }
  console.log(`[droplive] seeded ${exercises.size} exercises, ${recent.length} workouts, ${body.length} body check-ins, ${cardio.length} cardio sessions, and ${records.length} exercise records`);
}

await waitForServer();
await signIn();
const exercises = await seedExercises();
const { program, templates } = await seedProgram(exercises);
await seedWorkouts(exercises, program, templates);
await seedBodyAndCardio();
await verify(exercises);
