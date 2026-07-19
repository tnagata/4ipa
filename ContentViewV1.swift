import SwiftUI

// 評価項目のデータ構造
struct CemaOption: Identifiable, Hashable {
    let id = UUID()
    let score: Int
    let label: String
}

struct CemaQuestion: Identifiable {
    let id: Int
    let title: String
    let options: [CemaOption]
}

struct ContentView: View {
    // 画面遷移を管理する状態 (0: 規約画面, 1: 評価画面, 2: 結果画面)
    @State private var currentScreen = 0
    
    // ユーザーの回答を保持する辞書（項目ID -> 選択されたスコア。未選択はnil）
    @State private var answers: [Int: Int] = [:]
    
    // 10個の質問データ
    let questions = getCemaQuestions()
    
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
                    questions: questions,
                    answers: $answers,
                    onNavigateToResult: { currentScreen = 2 }
                )
            case 2:
                ResultView(
                    questions: questions,
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
struct ResultView: View {
    let questions: [CemaQuestion]
    let answers: [Int: Int]
    let onReset: () -> Void
    
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
                        
                        Text("\(calculation.totalScore) 点")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(resultColor)
                        
                        if calculation.unansweredCount > 0 {
                            Text("(未入力項目 \(calculation.unansweredCount) 件によるペナルティ分を含む)")
                                .font(.system(size: 11))
                                .foregroundColor(.red)
                        }
                        
                        if calculation.isQuestion6Minus10Selected {
                            Text("(項目⑥-10点選択による組織崩壊隠しペナルティ -10点 適用済)")
                                .font(.system(size: 11, weight: .bold))
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
                        .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
                    
                    Spacer(minLength: 20)
                    
                    Text("※本試用版へのフィードバックやロジック改善の提案がございましたら、開発グループメールアドレスまでお寄せください。")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineSpacing(3)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, 16)
            
            Button(action: onReset) {
                Text("トップに戻って再評価する")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.46, green: 0.46, blue: 0.46))
                    .cornerRadius(8)
            }
            .padding(16)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98).edgesIgnoringSafeArea(.all))
    }
    
    // スコア計算用構造体
    struct ScoreCalculation {
        let totalScore: Int
        let unansweredCount: Int
        let isQuestion6Minus10Selected: Bool
    }
    
    private func calculateScore() -> ScoreCalculation {
        var score = 0
        var unanswered = 0
        var q6SelectedMinus10 = false
        
        for question in questions {
            if let answer = answers[question.id] {
                score += answer
                if question.id == 6 && answer == -10 {
                    q6SelectedMinus10 = true
                }
            } else {
                score -= 1 // 未入力ペナルティ
                unanswered += 1
            }
        }
        
        if q6SelectedMinus10 {
            score -= 10 // 隠しペナルティ
        }
        
        return ScoreCalculation(
            totalScore: score,
            unansweredCount: unanswered,
            isQuestion6Minus10Selected: q6SelectedMinus10
        )
    }
}

// --- 評価項目マスターデータ定義 ---
func getCemaQuestions() -> [CemaQuestion] {
    return [
        CemaQuestion(
            id: 1,
            title: "項目①：製品による社会的事故・問題の有無",
            options: [
                CemaOption(score: 3, label: "【+3点】過去5年間、製品事故やシステム障害はゼロであり、潜在リスクの先手管理が徹底されている。"),
                CemaOption(score: 0, label: "【 0点】目立った社会的事故・問題は起こしていない。"),
                CemaOption(score: -1, label: "【-1点】トラブルはあったが、社内や一部の顧客対応で解決し、公になっていない。"),
                CemaOption(score: -3, label: "【-3点】ニュースやSNSで一時的に取り上げられ、社会的な信頼を部分的に損なった。"),
                CemaOption(score: -5, label: "【-5点】連日メディアで報道され、インフラ停止や行政処分など、致命的な社会問題に発展した。"),
                CemaOption(score: -10, label: "【-10点】行政処分やメディア報道が複数回発生した。")
            ]
        ),
        CemaQuestion(
            id: 2,
            title: "項目②：事後対応・説明責任（迅速さと誠実さ）",
            options: [
                CemaOption(score: 3, label: "【+3点】トラブル時、経営層自らが迅速に（24時間以内）記者会見を開き、透明性の高い情報開示と補償を自発的に行った。"),
                CemaOption(score: 0, label: "【 0点】起きた問題に対して、一般的な手続きに則って遅滞なく説明責任を果たした。"),
                CemaOption(score: -3, label: "【-3点】会見や情報開示が後手に回り、メディアや被害者への言い訳や原因の矮小化（過小評価）が見られた。"),
                CemaOption(score: -5, label: "【-5点】事実の隠蔽、嘘の報告、あるいは現場へのトカゲの尻尾切り（責任転嫁）を行い、社会的な大糾弾を招いた。"),
                CemaOption(score: -10, label: "【-10点】システム問題の被害者の中に自殺者が出ているにもかかわらず、10年以上「子会社のしたことで何も答えられない」と言い張り続け、救済処置を一切取っていない。経営層の倫理観が崩壊している。")
            ]
        ),
        CemaQuestion(
            id: 3,
            title: "項目③：子会社へのガバナンス",
            options: [
                CemaOption(score: 3, label: "【+3点】グループ一体となって同一の厳しい品質・倫理基準が共有され、親会社による監査とサポートが実効的に機能している。"),
                CemaOption(score: 0, label: "【 0点】子会社の経営や品質管理において、特に目立った不祥事や統治不全は起きていない。"),
                CemaOption(score: -3, label: "【-3点】子会社の管理が甘く、子会社独自の判断による不祥事や品質トラブルが散発している。"),
                CemaOption(score: -5, label: "【-5点】子会社で重大な不正や事故が発生した際、親会社が「別法人だから」とトカゲの尻尾切りを行い、統治責任を放棄した。"),
                CemaOption(score: -10, label: "【-10点】親会社が子会社を完全に「不祥事や泥をかぶせるための隠れみの」として扱い、子会社の不良システムが原因で人命や人権に関わる大スキャンダル（海外含む）が起きても、親会社の経営陣は「子会社に任せている」の一点張り。")
            ]
        ),
        CemaQuestion(
            id: 4,
            title: "項目④：委託先企業へのガバナンス（多重下請け・丸投げ）",
            options: [
                CemaOption(score: 3, label: "【+3点】委託先・パートナー企業を対等な仲間として尊重し、適正な価格と納期で契約し、共に品質向上に取り組んでいる。"),
                CemaOption(score: 0, label: "【 0点】外注管理において、法律（下請法など）を遵守し、一般的なトラブル防止策を行っている。"),
                CemaOption(score: -3, label: "【-3点】コスト削減のために委託先に無理な納期や価格を押し付け、品質低下の兆候が見えるが黙認している。"),
                CemaOption(score: -5, label: "【-5点】実質的な開発・保守を多重下請けの最底辺に「丸投げ」しており、何か事故が起きると委託先に損害賠償をふっかけるなど責任を押し付ける。"),
                CemaOption(score: -10, label: "【-10点】「自社にはもうシステムの中身がわかる技術者が一人もいない」状態まで丸投げが進んでおり、委託先を奴隷のように買いたたいた結果、現場のモラルが崩壊して意図的なデータ偽装やバックドアの組み込みなどが起きても、それにすら何年も気づかないような状況である。")
            ]
        ),
        CemaQuestion(
            id: 5,
            title: "項目⑤：製品の設計・開発・保守能力の向上への投資",
            options: [
                CemaOption(score: 3, label: "【+3点】新規開発やレガシーシステムの刷新や、保守・開発人員の確保・教育に、経営層が十分な予算を継続投入している。"),
                CemaOption(score: 0, label: "【 0点】現状の体制を維持するための最低限の投資は行われている。"),
                CemaOption(score: -3, label: "【-3点】コスト削減の圧力が強く、開発・保守現場から「人員不足」「設備・ツールの老朽化」の悲鳴が上がっているが放置されている。"),
                CemaOption(score: -5, label: "【-5点】利益最優先で保守予算や安全対策費を極限まで削り、現場の体制が完全に崩壊（または多重下請けに丸投げ）している。"),
                CemaOption(score: -10, label: "【-10点】社員の技術力が著しく低く、QA部門が「監査」をしても全く問題を発見する能力が無かった。また監査内容を説明するように求めても沈黙を通した。")
            ]
        ),
        CemaQuestion(
            id: 6,
            title: "項目⑥：品質重視の文化成熟度（トップのコミットと現場の権限）",
            options: [
                CemaOption(score: 5, label: "【+5点】トップメッセージで「品質第一」が常態化しており、品質部長が「出荷停止」などの強力な権限を経営層に阻害されずに行使できる。"),
                CemaOption(score: 0, label: "【 0点】品質部門は独立しているが、最終的な経営判断（納期やコスト）に押し切られることが稀にある。"),
                CemaOption(score: -3, label: "【-3点】トップの関心が利益や株価に偏っており、品質部門の立場が弱く、現場の意見が経営層に届かない。"),
                CemaOption(score: -5, label: "【-5点】品質部門が形骸化（お飾り）しており、経営層の圧力によって「問題があっても出荷せざるを得ない」倫理崩壊が起きている。"),
                CemaOption(score: -10, label: "【-10点】トップは品質問題を起こしても「政治献金の多い大会社は大丈夫」と考えている。現場の品質部門の実体は「くずの集まり(QA)」で、技術力はない上、「大会社はプロジェクトが沢山あるので問題もたくさん出て当然」と考えている。上から下まで「企業は社会の公器」という言葉すら知らない。")
            ]
        ),
        CemaQuestion(
            id: 7,
            title: "項目⑦：リストラや従業員の離職率の異常性",
            options: [
                CemaOption(score: 3, label: "【+3点】従業員を最大の財産（人財）と位置づけ、リスキリングや環境改善への投資を惜しまず、離職率が極めて低い。"),
                CemaOption(score: 0, label: "【 0点】業界平均並みの健全な離職率であり、不当な人員削減などは行われていない。"),
                CemaOption(score: -3, label: "【-3点】短期的な業績改善のために「早期退職」と称したリストラを繰り返し、社内の士気や技術の継承が衰退している。"),
                CemaOption(score: -5, label: "【-5点】優秀な技術者や現場の中核メンバーが愛想を尽かして大量離職しており、残された現場は精神的・肉体的に崩壊寸前である。"),
                CemaOption(score: -10, label: "【-10点】経営陣が社員を「いつでも替えが利くコスト（歯車）」としか見ておらず、不当解雇やパワハラが横行し、口コミサイト等で「この会社は墓場」「絶対に入社するな」と酷評され、組織のモラルと技術基盤が完全に消失している。定期採用をしても人が集まらないので、長年続いた定期採用をやめた。")
            ]
        ),
        CemaQuestion(
            id: 8,
            title: "項目⑧：（公言した）技術・品質向上施策の実行力と効果",
            options: [
                CemaOption(score: 3, label: "【+3点】経営層が公約した技術投資や再発防止策が、具体的な数値目標と共に着実に実行され、確実な成果を上げている。"),
                CemaOption(score: 0, label: "【 0点】発表した計画は、概ねスケジュール通りに進捗し、最低限の効果を出している。"),
                CemaOption(score: -3, label: "【-3点】事故の直後だけ立派な「再発防止委員会」を立ち上げるが、喉元を過ぎれば予算を縮小し、施策が形骸化している。"),
                CemaOption(score: -5, label: "【-5点】過去に何度も「生まれ変わります」と記者会見で誓った施策が何一つ実行されておらず、同じ原因による大事故を何度も繰り返している。"),
                CemaOption(score: -10, label: "【-10点】デジタル大臣から行政指導を受けて役員が頭を下げているところをテレビで放映されても上から下まで慣れっこでポーズだけ「真摯に受け止める」と言いながら本質的な改善を1ミリも行っていない。度重なる品質問題に対する謝罪サイトで「開発プロセスの定義を半年以内に作成し、公表する」と宣言しながら、3年たっても公表されていない。また連絡先の電話番号は「現在使われていません」のテープ音声。")
            ]
        ),
        CemaQuestion(
            id: 9,
            title: "項目⑨：経営層自身の倫理的問題（スキャンダル・法令違反）",
            options: [
                CemaOption(score: 3, label: "【+3点】経営陣が高い倫理観を体現し、社会的良識に基づいた経営姿勢を社内外に一貫して示し続けている。"),
                CemaOption(score: 0, label: "【 0点】経営層において、法令違反や社会的批判を浴びるようなスキャンダルは発生していない。"),
                CemaOption(score: -3, label: "【-3点】経営陣の一部に、パワハラ、不適切な交際、公私人間の混同などの噂や小規模な問題が起きているが、組織的にうやむやにされている。"),
                CemaOption(score: -5, label: "【-5点】不正会計、インサイダー取引、経営陣の内紛、あるいは大規模なハラスメントなど、トップ直結の法令違反・スキャンダルが発覚した。"),
                CemaOption(score: -10, label: "【-10点】2016年6月に会長による女性に対する不適切な行動が報じられ、取締役を辞任した。トップの座が「社会の公器」ではなく「私利私欲と利権を貪るための椅子」に変貌している。")
            ]
        ),
        CemaQuestion(
            id: 10,
            title: "項目⑩：将来製品・サービスの予告（誠実性と実現力）",
            options: [
                CemaOption(score: 3, label: "【+3点】将来のロードマップが極めて誠実かつ現実的に設計されており、予告された技術や製品は予定通り（またはそれ以上で）着実に実現される。"),
                CemaOption(score: 0, label: "【 0点】予告した製品やサービスのリリースにおいて、一般的な範囲の遅延などはあっても、最終的には形にしている。"),
                CemaOption(score: -3, label: "【-3点】株価維持や競合牽制のために、まだ影も形もない技術を「まもなく完成」と大風呂敷を広げ、現場に不可能なデスマーチを強いている。"),
                CemaOption(score: -5, label: "【-5点】実現不可能な納期やスペックで大口案件を受注し、案の定開発が頓挫。それを何年も隠蔽し続けた末にプロジェクトが炎上・破綻した。"),
                CemaOption(score: -10, label: "【-10点】カナダのAI開発企業とパートナー契約を結び、新システムをぶち上げたが2年たっても売れるような開発システムにならなかった。最大の要因は経営層に技術力がないためパートナーの技術力を過大評価したことである。25年前も英国の企業の技術力と低倫理性を見抜けず、買収したが巨大な負の遺産になりつつある。これも自社に技術力と倫理観が欠如しているから見抜けないわけである。")
            ]
        )
    ]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
