import SwiftUI

// 評価項目のデータ構造
struct CemaOption: Identifiable, Hashable, Decodable {
    let id = UUID()
    let score: Int
    let label: String
    
    enum CodingKeys: String, CodingKey {
        case score
        case label
    }
}

struct CemaQuestion: Identifiable, Decodable {
    let id: Int
    let title: String
    let options: [CemaOption]
}

struct CemaData: Decodable {
    let questions: [CemaQuestion]
    let weights: [[Double]]
    let bias: [Double]
}

struct ContentView: View {
    // 画面遷移を管理する状態 (0: 規約画面, 1: 評価画面, 2: 結果画面)
    @State private var currentScreen = 0
    
    // ユーザーの回答を保持する辞書（項目ID -> 選択されたスコア。未選択はnil）
    @State private var answers: [Int: Int] = [:]
    
    // CEMAの全データ（質問、重み、バイアス）をJSONから読み込む
    let cemaData = loadCemaData()
    
    var body: some View {
        Group {
            switch currentScreen {
            case 0:
                DisclaimerView(
                    onAgree: { currentScreen = 1 },
                    onDisagree: {
                        // アプリを終了させる（iOSの一般的な終了処理）
                        exit(0)
                    }
                )
            case 1:
                EvaluationView(
                    questions: cemaData.questions,
                    answers: $answers,
                    onNavigateToResult: { currentScreen = 2 }
                )
            case 2:
                ResultView(
                    cemaData: cemaData,
                    answers: answers,
                    onReset: {
                        answers.removeAll()
                        currentScreen = 1
                    }
                )
            default:
                DisclaimerView(onAgree: { currentScreen = 1 }, onDisagree: { exit(0) })
            }
        }
    }
}

// --- 【画面1】免責同意・防御画面 ---
struct DisclaimerView: View {
    let onAgree: () -> Void
    let onDisagree: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("企業倫理成熟度評価 (CEMA)v.0.2\n- 試用版プロトタイプ -")
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .padding(.vertical, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("【重要】本アプリのご利用に関する規約と免責事項")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.bottom, 4)
                    
                    Text("""
                        本アプリは、組織の「企業倫理成熟度」を自己診断・評価するための【研究開発中の試用版（プロトタイプ）】です。今後のアップデートにより、評価基準や仕様は予告なく変更される場合があります。試用期間中はすべての機能を無償でご利用いただけます。

                        以下の利用規約および免責事項をよくお読みいただき、同意の上でご利用ください。

                        1. 目的の限定
                        本アプリは、ユーザーが【自組織（自社）の現状を客観的に把握し、内部での品質改善活動および経営層への働きかけを行うこと】を唯一の目的として提供されています。特定の他社を誹謗中傷する目的での使用を固く禁じます。

                        2. データおよび評価結果の責任
                        選択肢の判定基準は、過去の一般的なITインシデント事例を参考に学術的・統計的に作成された一般的なモデルです。特定の企業を直接指定・評価するものではありません。アプリによって算出されたスコアおよび改善提案は、【ユーザー自身の入力に基づく自己申告の診断結果】であり、開発者はその正確性、正当性、および結果から生じるいかなる損害（社会的信用への影響を含む）についても一切の責任を負いません。

                        3. フィードバックの受付
                        本アプリの評価ロジックの改善提案やバグ報告などがございましたら、以下のグループメールアドレスまでご連絡ください。
                        
                        お問い合わせ先：(※グループメールアドレスを想定)
                        """)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: onDisagree) {
                    Text("同意しない")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.62, green: 0.62, blue: 0.62))
                        .cornerRadius(8)
                }
                
                Button(action: onAgree) {
                    Text("同意して開始")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.83, green: 0.18, blue: 0.18))
                        .cornerRadius(8)
                }
            }
            .padding(16)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all))
    }
}

// --- 【画面2】10尺度の評価入力画面 ---
struct EvaluationView: View {
    let questions: [CemaQuestion]
    @Binding var answers: [Int: Int]
    let onNavigateToResult: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("企業倫理成熟度評価 (CEMA)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("すべての項目は過去5年間の最悪・最低なインシデントを元に選択してください（未入力は自動的に -1点 ）。\n※選択肢には社会的に公知となった某社の重大インシデント例が含まれています。自社においてこれらに類する事故や事象があった場合は、該当する項目にチェックを入れてください。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.83, green: 0.18, blue: 0.18))
                    .lineSpacing(3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(questions) { question in
                        QuestionCard(question: question, selectedScore: Binding(
                            get: { answers[question.id] },
                            set: { newValue in answers[question.id] = newValue }
                        ))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            Button(action: onNavigateToResult) {
                Text("組織の倫理成熟度を判定する")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.12, green: 0.53, blue: 0.90))
                    .cornerRadius(8)
            }
            .padding(16)
            .background(Color.white)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.bottom))
    }
}

// 質問カードのコンポーネント
struct QuestionCard: View {
    let question: CemaQuestion
    @Binding var selectedScore: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                .fixedSize(horizontal: false, vertical: true)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(question.options) { option in
                    Button(action: {
                        selectedScore = option.score
                    }) {
                        HStack(alignment: .top, spacing: 10) {
                            // ラジオボタンの円
                            ZStack {
                                Circle()
                                    .stroke(selectedScore == option.score ? Color(red: 0.12, green: 0.53, blue: 0.90) : Color.gray, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                
                                if selectedScore == option.score {
                                    Circle()
                                        .fill(Color(red: 0.12, green: 0.53, blue: 0.90))
                                        .frame(width: 10, height: 10)
                                }
                            }
                            .padding(.top, 2)
                            
                            Text(option.label)
                                .font(.system(size: 14))
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// --- 【画面3】診断結果・経営層への提言画面 ---
// calculateScore() の戻り値型
struct ScoreResult {
    let totalScore: Double
    let unansweredCount: Int
}

struct ResultView: View {
    let cemaData: CemaData
    let answers: [Int: Int]
    let onReset: () -> Void
    
    private var questions: [CemaQuestion] {
        cemaData.questions
    }
    
    // --- JSONから読み込んだweights・biasを使った加重総和スコア計算 ---
    // weights[i][j]: 質問i が 出力次元j に与える重み（10×10行列）
    // bias[j]: 各出力次元のバイアス（長さ10のベクトル）
    // totalScore = Σ_j ( Σ_i (x[i] * weights[i][j]) + bias[j] )
    private func calculateScore() -> ScoreResult {
        let weights = cemaData.weights   // [[Double]] (10×10)
        let bias    = cemaData.bias      // [Double]   (10)
        let numQuestions = questions.count
        let outputDim = bias.count
        
        // 未回答は -1点 のペナルティとして扱う
        var inputVector = [Double](repeating: -1.0, count: numQuestions)
        var unansweredCount = 0
        for (index, question) in questions.enumerated() {
            if let score = answers[question.id] {
                inputVector[index] = Double(score)
            } else {
                unansweredCount += 1
                // inputVector[index] は既に -1.0
            }
        }
        
        // 加重総和: output[j] = Σ_i( x[i] * weights[i][j] ) + bias[j]
        var outputVector = [Double](repeating: 0.0, count: outputDim)
        for j in 0..<outputDim {
            var sum = 0.0
            for i in 0..<numQuestions {
                // weights[i] が存在し、かつ j 列が存在する場合のみ加算
                if i < weights.count && j < weights[i].count {
                    sum += inputVector[i] * weights[i][j]
                }
            }
            if j < bias.count {
                sum += bias[j]
            }
            outputVector[j] = sum
        }
        
        // 全出力次元を合計してスカラーのtotalScoreを算出
        let totalScore = outputVector.reduce(0.0, +)
        
        return ScoreResult(
            totalScore: totalScore,
            unansweredCount: unansweredCount
        )
    }
    

    var body: some View {
        // --- スコア計算ロジック ---
        let calculation = calculateScore()
        
        let resultTitle: String
        let resultMessage: String
        let resultColor: Color
        
        if calculation.totalScore >= 20 {
            resultTitle = "【優良】倫理成熟企業モデル"
            resultMessage = "品質文化が経営トップから現場まで極めて高いレベルで浸透しています。今後も現場の品質部長の出荷停止権限などの強い独立性を維持・サポートし、この健全なガバナンス体制を継続してください。"
            resultColor = Color(red: 0.18, green: 0.49, blue: 0.20) // 緑
        } else if calculation.totalScore >= 0 {
            resultTitle = "【注意】部分的不健全組織"
            resultMessage = "現時点では致命的な崩壊には至っていませんが、一部の項目において投資不足や隠蔽体質、丸投げの兆候が見られます。今すぐトップ層がコミットメントを見直し、現場の悲鳴に耳を傾けて投資を再開しなければ、近い将来に重大な社会的事故に発展するリスクがあります。"
            resultColor = Color(red: 0.94, green: 0.42, blue: 0.0) // オレンジ
        } else {
            resultTitle = "【警告】倫理・技術の完全崩壊組織"
            resultMessage = "組織の倫理観および技術力が、経営層から現場に至るまで完全に麻痺・崩壊しています。不祥事の隠蔽、現場への責任転嫁、形骸化した再発防止策はすでに社会に見透かされています。「企業は社会の公器」という原点に立ち返り、経営陣の刷新、ならびに品質部門の権限と技術力を根本から再構築しない限り、企業の存続自体が不可能です。"
            resultColor = Color(red: 0.78, green: 0.16, blue: 0.16) // 赤
        }
        
        return VStack(spacing: 0) {
            Text("診断結果レポート")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // スコア表示部分
                    VStack(spacing: 8) {
                        Text("総合倫理成熟度スコア")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.1f 点", calculation.totalScore))
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(resultColor)
                        
                        if calculation.unansweredCount > 0 {
                            Text("(未入力項目 \(calculation.unansweredCount) 件によるペナルティ分を含む)")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    
                    Divider()
                    
                    // 組織判定
                    Text(resultTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(resultColor)
                    
                    // 提言メッセージ
                    Text(resultMessage)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            Button(action: onReset) {
                Text("最初からやり直す")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.12, green: 0.53, blue: 0.90))
                    .cornerRadius(8)
            }
            .padding(16)
            .background(Color.white)
        }
        .background(Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all))
    }
}


func loadCemaData() -> CemaData {
    let jsonFileName = "cema_data"
    let jsonFileExtension = "json"
    
    // 1. Bundle.main からの読み込みを試行
    if let url = Bundle.main.url(forResource: jsonFileName, withExtension: jsonFileExtension) {
        return loadCemaData(from: url)
    }
    
    // 2. 動的にモジュール用バンドルを探索（SwiftPM環境下でのビルド対策）
    if let bundleURL = Bundle.main.urls(forResourcesWithExtension: "bundle", subdirectory: nil)?
        .first(where: { $0.lastPathComponent.contains("AppModule") }),
       let bundle = Bundle(url: bundleURL),
       let url = bundle.url(forResource: jsonFileName, withExtension: jsonFileExtension) {
        return loadCemaData(from: url)
    }
    
    print("Error: \(jsonFileName).\(jsonFileExtension) not found.")
    return CemaData(questions: [], weights: [], bias: [])
}

private func loadCemaData(from url: URL) -> CemaData {
    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(CemaData.self, from: data)
    } catch {
        print("Error decoding CEMA JSON data: \(error)")
        return CemaData(questions: [], weights: [], bias: [])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
