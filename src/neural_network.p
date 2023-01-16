INPUTS :: 784;
OUTPUTS :: 10;
HIDDEN_LAYERS :: 2;
NEURONS_PER_HIDDEN_LAYER :: 16;
LEARNING_RATE :: 0.1;

Layer :: struct {
    activations: *f64;
    weights: *f64;
    errors: *f64;
    biases: *f64;
    num_neurons: u32;
}

Neural_Network :: struct {
    layers: []Layer;
    num_hidden_layers: u32;
    num_neurons_per_hidden_layer: u32;
    num_outputs: u32;
}

get_random_f64_zero_to_one :: () -> f64 {
    return cast(f64) rand() / xx RAND_MAX;
}


/* Activation functions */
relu :: (x: f64) -> f64 {
    if 0.01 * x > x {
        return 0.01 * x;
    }
    return x;
}

layer_relu :: (layer: *Layer) {
    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] = relu(layer.activations[i]);
    }
}

relu_prime :: (x: f64) -> f64 {
    if x <= 0 {
        return 0.01;
    }
    return 1.0;
}

sigmoid :: (x: f64) -> f64 {
    return 1.0 / (1.0 + exp(-x));
}

layer_sigmoid :: (layer: *Layer) {
    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] = sigmoid(layer.activations[i]);
    }
}

sigmoid_prime :: (x: f64) -> f64 {
    return x * (1.0 - x);
}

softmax :: (layer: *Layer, prev_layer: *Layer, label: f64) -> f64 {
    // get max for stability
    max := layer.activations[0];
    for i := 1; i < layer.num_neurons; ++i {
        if layer.activations[i] > max {
            max = layer.activations[i];
        }
    }

    // calc exp sum
    exp_sum := 0.0;
    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] -= max;
        exp_activation := exp(layer.activations[i]);
        exp_sum += exp_activation;
        layer.activations[i] = exp_activation;
    }

    // calc softmax for each neuron
    for i := 0; i < layer.num_neurons; ++i {
        layer.activations[i] /= exp_sum;
    }

    // calc loss
    loss := -log(layer.activations[cast(s32) label]) / xx layer.num_neurons;
    //loss := -layer.activations[cast(s32) label] + log(exp_sum);

    return loss;
}

abs_f64 :: (x: f64) -> f64 {
    if x < 0 return -x;
    return x;
}

init_neural_network :: (net: *Neural_Network) {
    net.num_hidden_layers = HIDDEN_LAYERS;
    net.num_neurons_per_hidden_layer = NEURONS_PER_HIDDEN_LAYER;
    net.num_outputs = OUTPUTS;

    srand(time(null));

    net.layers = allocate_array(HIDDEN_LAYERS + 2, Layer);
    layers := net.layers;

    // Initialize the input layer
    layers[0].num_neurons = INPUTS;
    layers[0].activations = xx malloc(layers[0].num_neurons * size_of(f64));

    // Initialize all other layers
    for i := 1; i < layers.count; ++i {
        layer := *layers[i];
        prev_layer := *layers[i - 1];

        if (i != layers.count - 1) layer.num_neurons = net.num_neurons_per_hidden_layer;
        else                       layer.num_neurons = net.num_outputs;
        
        layer.activations = xx malloc(layer.num_neurons * size_of(f64));
        layer.weights     = xx malloc(layer.num_neurons * prev_layer.num_neurons * size_of(f64));
        layer.errors      = xx malloc(layer.num_neurons * size_of(f64)); 
        layer.biases      = xx malloc(layer.num_neurons * size_of(f64)); 

        for j := 0; j < layer.num_neurons; ++j {
            for k := 0; k < prev_layer.num_neurons; ++k {
                layer.weights[j * prev_layer.num_neurons + k] = get_random_f64_zero_to_one();
            }
            layer.biases[j] = get_random_f64_zero_to_one();
        }
    }
}

train :: (net: *Neural_Network, epochs: u64) {
    dataset := load_mnist();

    loss := 0.0;
    batch_size := 5000;
    for i: u64 = 0; i < epochs; ++i {
        for j := 0; j < dataset.y_train.count; ++j {
            label := dataset.y_train[j];
            load_into_input_layer(net, *dataset.x_train[j * MNIST_IMG_BYTES]);
            loss += forward_propagate(net, label);
            if j % batch_size == 0 {
                printf("Loss: %lf\n", loss / xx batch_size);
                last_layer := *net.layers[net.layers.count - 1];
                print("Ground-Truth: % \t Accuracy-Prediction: %\n", label, last_layer.activations[cast(s32)label]);
                loss = 0.0;
            }

            //print("Input: % %\t Output: %\t Expected: %\n", training_set[j][0], training_set[j][1], net.layers[net.layers.count - 1].activations[0], training_labels[j]);
            back_propagate(net, dataset.y_train[j]);
        }
    }
}

load_into_input_layer :: (net: *Neural_Network, inputs: *f64) {
    input_layer := *net.layers[0];
    for i := 0; i < input_layer.num_neurons; ++i {
        input_layer.activations[i] = inputs[i];
    }
}

forward_propagate :: (net: *Neural_Network, label: f64) -> f64 {
    // hidden
    for i := 1; i < net.layers.count - 1; ++i {
        layer := *net.layers[i];
        prev_layer := *net.layers[i - 1];
        // For each neuron sum all the activations from the previous layer multiplied with their respective weights
        // and propagate these activation values forward through the whole network.
        for j := 0; j < layer.num_neurons; ++j {
            sum: f64 = layer.biases[j]; 
            for k := 0; k < prev_layer.num_neurons; ++k {
                sum += prev_layer.activations[k] * layer.weights[j * prev_layer.num_neurons + k];
            }
            layer.activations[j] = sigmoid(sum);
        }
    }

    // output
    layer := *net.layers[net.layers.count - 1];
    prev_layer := *net.layers[net.layers.count - 2];
    for i := 0; i < layer.num_neurons; ++i {
        sum: f64 = layer.biases[i]; 
        for j := 0; j < prev_layer.num_neurons; ++j {
            sum += prev_layer.activations[j] * layer.weights[i * prev_layer.num_neurons + j];
        }
        layer.activations[i] = sum;
    }
    return softmax(layer, prev_layer, label);
}

back_propagate :: (net: *Neural_Network, label: f64) {
    // Calculate the output error
    layer := *net.layers[net.layers.count - 1];
    for i := 0; i < layer.num_neurons; ++i {
        is_label := label == xx i;
        layer.errors[i] = layer.activations[i] - xx is_label;
    }

    // Propagate the error back through all of the hidden layers
    for i: s64 = net.layers.count - 2; i > 0; --i {
        layer = *net.layers[i];
        next_layer := *net.layers[i + 1];
        for j := 0; j < layer.num_neurons; ++j {
            error := 0.0;
            for k := 0; k < next_layer.num_neurons; ++k {
                error += next_layer.errors[k] * next_layer.weights[k * layer.num_neurons + j];
            }
            layer.errors[j] = error * sigmoid_prime(layer.activations[j]);
        }
    }

    // Update weights according to their error and learning rate
    for i: s64 = net.layers.count - 1; i > 0; --i {
        layer = *net.layers[i];
        prev_layer := *net.layers[i - 1];
        for j := 0; j < layer.num_neurons; ++j {
            layer.biases[j] -= layer.errors[j] * LEARNING_RATE;
            for k := 0; k < prev_layer.num_neurons; ++k {
                layer.weights[j * prev_layer.num_neurons + k] -= prev_layer.activations[k] * layer.errors[j] * LEARNING_RATE;
            }
        }
    }
}
