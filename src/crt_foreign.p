
// math
exp :: foreign (x: f64) -> f64;
expf :: foreign (f32) -> f32;

// random + time
time :: foreign (timer: *u64) -> u64;
printf :: foreign (cstring, f64);