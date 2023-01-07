INPUTS :: 2;
OUTPUTS :: 1;
HIDDEN_LAYERS :: 1;
NEURONS_PER_HIDDEN_LAYER :: 2;
LEARNING_RATE :: 0.1;

Layer :: struct {
    activations: *f64;
    weights: *f64;
    errors: *f64;
    biases: *f64;
    num_neurons: u32;
    num_weights_per_neuron: u32;
}

Neural_Network :: struct {
    layers: *Layer;
    num_inputs: u32;
    num_hidden_layers: u32;
    num_neurons_per_hidden_layer: u32;
    num_outputs: u32;
    num_layers: u32;
}

get_random_f64_zero_to_one :: () -> f64 {
    return cast(f64) rand() / cast(f64) RAND_MAX;
}

sigmoid :: (x: f64) -> f64 {
    return 1.0 / (1.0 + exp(-x));
}

sigmoid_derivative :: (x: f64) -> f64 {
    return x * (1.0 - x);
}

fast_sigmoid :: (x: f64) -> f64 {
    return x / (1.0 + abs_f64(x));
}

abs_f64 :: (x: f64) -> f64 {
    if x < 0 return -x;
    return x;
}

init_neural_network :: (net: *Neural_Network) {
    net.num_inputs = INPUTS;
    net.num_hidden_layers = HIDDEN_LAYERS;
    net.num_neurons_per_hidden_layer = NEURONS_PER_HIDDEN_LAYER;
    net.num_outputs = OUTPUTS;
    net.num_layers = HIDDEN_LAYERS + 2;

    srand(0);

    net.layers = xx malloc(net.num_layers * size_of(Layer));
    layers: *Layer = net.layers;

    for i: s64 = net.num_layers - 1; i >= 0; --i {
        layer := *layers[i];
        if i == net.num_layers - 1 {
            layer.num_neurons = net.num_outputs;
            layer.num_weights_per_neuron = 0;
        } else if i == 0 {
            layer.num_neurons = net.num_inputs;
            layer.num_weights_per_neuron = layers[i + 1].num_neurons;
        } else {
            layer.num_neurons = net.num_neurons_per_hidden_layer;
            layer.num_weights_per_neuron = layers[i + 1].num_neurons;
        }

        layer.activations = xx malloc(layer.num_neurons * size_of(f64));
        layer.errors      = xx malloc(layer.num_neurons * size_of(f64));
        layer.biases      = xx malloc(layer.num_neurons * size_of(f64));
        layer.weights     = xx malloc(layer.num_neurons * layer.num_weights_per_neuron * size_of(f64));

        for j := 0; j < layer.num_neurons; ++j {
            for k := 0; k < layer.num_weights_per_neuron; ++k {
                layer.weights[j * layer.num_weights_per_neuron + k] = get_random_f64_zero_to_one();
            }
            //layer.activations[j] = get_random_f64_zero_to_one();
            layer.biases[j] = get_random_f64_zero_to_one();
        }
    }
}

train :: (net: *Neural_Network, epochs: u32) {
    training_set_size := 4;
    training_set := {{0.0, 0.0}, {0.0, 1.0}, {1.0, 0.0}, {1.0, 1.0}};
    training_labels := {0.0, 1.0, 1.0, 0.0};

    for i := 0; i < epochs; ++i {
        for j := 0; j < training_set_size; ++j {
            load_inputs(net, training_set[j]);
            forward_propagate(net);
            print("Input: % %\t Output: %\t Expected: %\n", training_set[j][0], training_set[j][1], net.layers[net.num_layers - 1].activations[0], training_labels[j]);
            back_propagate(net, training_labels[j]);
            // print_weights(net);
            // best_output := get_best_output(net);
        }
    }
}

print_weights :: (net: *Neural_Network) {
    for i := 0; i < net.num_layers - 1; ++i {
        print("Layer %:\n", i);
        for j := 0; j < net.layers[i].num_neurons; ++j {
            print("Neuron %:\n", j);
            for k := 0; k < net.layers[i].num_weights_per_neuron; ++k {
                print("Weight %: %\n", k, net.layers[i].weights[j * net.layers[i].num_weights_per_neuron + k]);
            }
        }
    }
}

get_best_output :: (net: *Neural_Network) -> u32 {
    last_layer := *net.layers[net.num_layers - 1];
    max_idx := 0;
    max_value := last_layer.activations[0];
    for i := 1; i < last_layer.num_neurons; ++i {
        if last_layer.activations[i] > max_value {
            max_idx = i;
            max_value = last_layer.activations[i];
        }
    }
    return max_idx;
}

load_inputs :: (net: *Neural_Network, inputs: *f64) {
    input_layer := *net.layers[0];
    for i := 0; i < input_layer.num_neurons; ++i {
        input_layer.activations[i] = inputs[i];
    }
}

forward_propagate :: (net: *Neural_Network) {
    for i := 1; i < net.num_layers; ++i {
        layer := *net.layers[i];

        for j := 0; j < layer.num_neurons; ++j {
            prev_layer := *net.layers[i - 1];
            sum: f64 = layer.biases[j]; // bias
            for k := 0; k < prev_layer.num_neurons; ++k {
                sum += prev_layer.activations[k] * prev_layer.weights[k * prev_layer.num_weights_per_neuron + j];
            }
            layer.activations[j] = sigmoid(sum);
        }
    }
}

loss_func :: (target: f64, x: f64) -> f64 {
    return (target - x) * (target - x);
}


back_propagate :: (net: *Neural_Network, target: f64) {
    layer := *net.layers[net.num_layers - 1];
    for i := 0; i < layer.num_neurons; ++i {
        error := target - layer.activations[i]; 
        layer.errors[i] = error * sigmoid_derivative(layer.activations[i]);
        print("Target: %, Activation: %, Error: %\n", target, layer.activations[i], error);
        //print("Error: %\n", layer.errors[i]);
    }

    for i: s64 = net.num_layers - 2; i > 0; --i {
        layer = *net.layers[i];
        next_layer := *net.layers[i + 1];
        for j := 0; j < layer.num_neurons; ++j {
            error := 0.0;
            for k := 0; k < layer.num_weights_per_neuron; ++k {
                error += next_layer.errors[k] * layer.weights[j * layer.num_weights_per_neuron + k];
            }
            layer.errors[j] = error * sigmoid_derivative(layer.activations[j]);
        }
    }

    for i: s64 = net.num_layers - 2; i >= 0; --i {
        layer = *net.layers[i];
        next_layer := *net.layers[i + 1];
        for j := 0; j < layer.num_weights_per_neuron; ++j {
            next_layer.biases[j] += next_layer.errors[j] * LEARNING_RATE;
            for k := 0; k < layer.num_neurons; ++k {
                layer.weights[k * layer.num_weights_per_neuron + j] = layer.activations[k] * next_layer.errors[j] * LEARNING_RATE;
            }
        }
    }
}
