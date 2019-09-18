import Cocoa
import CreateML

// load up the file data into a MLDataTable
let data = try MLDataTable(contentsOf: URL(fileURLWithPath: "/Users/amerigo/Desktop/twitter-sanders-apple3.csv"))

// split the data into 80% for training data and 20% for testing data
let (trainingData, testingData) = data.randomSplit(by: 0.8, seed: 5)

// create a new instance of the MLText classifier and train our model by using the training data
let sentimentClassifier = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "class")

// test the model against the testing dataset
let evaluationMetrics = sentimentClassifier.evaluation(on: testingData)

// calculate the accuracy (in percentage)
let evaluationAccuracy = (1.0 - evaluationMetrics.classificationError) * 100

// save the model
let metadata = MLModelMetadata(author: "Amerigo Mancino", shortDescription: "A model trained to classify sentiment on Tweets", version: "1.0")
try sentimentClassifier.write(to: URL(fileURLWithPath: "/Users/amerigo/Desktop/TweetSentimentClassifier.mlmodel"))

// test our brand new model
try sentimentClassifier.prediction(from: "@Apple is a terrible company")
try sentimentClassifier.prediction(from: "I just found the best restaurant ever and it's @DuckanWaffle")
try sentimentClassifier.prediction(from: "I think @CocaCola ads are just ok")
