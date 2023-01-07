
// math
exp :: foreign (x: f64) -> f64;

// random + time
RAND_MAX :: 32767;
rand :: foreign () -> s32;
srand :: foreign (seed: u32);
time :: foreign (timer: *u64) -> u64;